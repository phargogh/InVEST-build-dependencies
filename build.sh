#!/usr/bin/env bash

# Check tool dependencies.
which gcloud > /dev/null || echo "gcloud CLI is required but could not be found."
which sshpass > /dev/null || echo "sshpass is required but could not be found."
which jq > /dev/null || echo "jq is required but could not be found."


rev=`hg log -r. --template="r{rev}-{node|short}-v{date(date, '%Y%m%d')}"`
templatename="jenkins-win2008r2-$rev"
tempmachinename=$templatename-setupinprogress
zone=us-west1-a
project=natcap-build-cluster
serviceaccount=jenkins@$project.iam.gserviceaccount.com
dependencybucket=natcap-build-cluster-dependencies

# Fetch keys from project metadata, reformat as authorized keys and
# upload authorized keys to storage bucket.
all_keys=allkeys.txt
auth_keys_file=project-authorized_keys
jenkinsagentpublickey=jenkins-agent-id_rsa.pub
gcloud compute project-info --project=$project \
    describe --format=json | jq -r '.commonInstanceMetadata.items[] | select(.key == "sshKeys") | .value' \
    > $all_keys
cat $all_keys | sed 's|^[a-z]\+:||' | awk NF > $auth_keys_file
grep jenkins $all_keys | sed 's|^[a-z]\+:||' > $jenkinsagentpublickey

gsutil cp $auth_keys_file gs://$dependencybucket/$auth_keys_file
gsutil cp $jenkinsagentpublickey gs://$dependencybucket/$jenkinsagentpublickey


# create an instance with the target setup script
echo "Setting up instance " $tempmachinename
gcloud compute instances create $tempmachinename \
    --boot-disk-auto-delete \
    --boot-disk-size=50GB \
    --boot-disk-type=pd-standard \
    --machine-type=n1-standard-2 \
    --metadata-from-file sysprep-specialize-script-ps1=install_windows_build_dependencies.ps1 \
    --zone=$zone \
    --image-project=windows-cloud \
    --image=windows-server-2008-r2-dc-v20180213 \
    --service-account=$serviceaccount \
    --project=$project


echo "Building machine.  This may take some time."
echo "In another shell, execute this command to see the console output: "
echo "    $ gcloud compute instances --project=$project get-serial-port-output $tempmachinename --zone=$zone"
progressfile=.consoleprogress
latestlogging=.latestlogging
echo 0 > $progressfile
while true
do
    startbyte=$(grep -o -e '[0-9]\+' $progressfile)
    gcloud compute --project=$project instances get-serial-port-output \
        $tempmachinename --start=$startbyte --zone=us-west1-a 1> $latestlogging 2> $progressfile
    # only print logging if there's more to print.
    if [[ $(tr -d '[:space:]' < $latestlogging | wc -c | grep -o -e '^[0-9]\+') -ge 1 ]]
    then
        cat $latestlogging
    fi

    # check if setup completed.
    cat $latestlogging | egrep -i 'activation successful'
    if [ $? -eq 0 ]
    then
        break
    else
        # computer setup is still in progress 
        sleep 2
    fi
done

# Set up our SSH user and copy keys over.
passwordfile=jenkins-windows-pw.temp
gcloud beta compute reset-windows-password $tempmachinename \
    --project=$project --zone=$zone --user=jenkins --quiet | grep password | awk '{ print $2 }' > $passwordfile
externalIP=$(gcloud compute instances describe $tempmachinename --zone=$zone --project=$project --format="value(networkInterfaces[0].accessConfigs[0].natIP)")
sshpass -f $passwordfile ssh jenkins@$externalIP "mkdir .ssh; cd .ssh; gsutil cp gs://$dependencybucket/$auth_keys_file authorized_keys; gsutil cp gs://$dependencybucket/$jenkinsagentpublickey id_rsa.pub"

# Reset the password once again so we can't know it and it won't show up in the logs.
gcloud beta compute reset-windows-password $tempmachinename \
    --project=$project --zone=$zone --user=jenkins --quiet > /dev/null

echo "Shutting down VM so we can image it."
# Computer setup is complete.  Shut it down so we can image it.
# Wait until the VM is completely shut down before imaging.
gcloud compute --project=$project instances stop $tempmachinename --zone=$zone
while true
do
    gcloud compute --project=$project \
        instances describe $tempmachinename --zone=$zone | grep status | grep TERMINATED
    if [ $? -eq 0 ]
    then
        break
    else
        sleep 2
    fi
done


echo "Imaging $tempmachinename as $templatename"
gcloud compute images create $templatename \
    --source-disk=$tempmachinename \
    --source-disk-zone=$zone \
    --family=windows-2008-r2 \
    --project=$project

# now, delete the temporary VM without prompting for confirmation
echo "Deleting VM $tempmachinename"
gcloud compute instances delete --quiet $tempmachinename --zone=$zone --project=$project



# TODO: update an existing template for jenkins windows slaves.
# TODO: Add tags for jenkins cluster

echo "Creating template from image " $templatename
gcloud compute instance-templates create $templatename \
    --boot-disk-auto-delete \
    --boot-disk-size=50GB \
    --boot-disk-type=pd-standard \
    --machine-type=n1-standard-2 \
    --metadata-from-file sysprep-specialize-script-ps1=install_windows_build_dependencies.ps1 \
    --region=$zone \
    --image-project=$project \
    --image=$templatename \
    --service-account=$serviceaccount \
    --project=$project
echo "Done."
