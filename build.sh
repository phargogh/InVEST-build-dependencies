#!/usr/bin/env bash



rev=`hg log -r. --template="r{rev}-{node|short}-v{date(date, '%Y%m%d')}"`
templatename="jenkins-win2008r2-$rev"
tempmachinename=$templatename-setupinprogress
zone=us-west1-a

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
    --service-account=jenkins-build-cluster@natcap-servers.iam.gserviceaccount.com


echo "Building machine.  This may take some time."
echo "In another shell, execute this command to see the console output: "
echo "    $ gcloud compute instances --project=natcap-servers get-serial-port-output $tempmachinename --zone=$zone"
progressfile=.consoleprogress
latestlogging=.latestlogging
echo 0 > $progressfile
while true
do
    startbyte=$(egrep -o '[0-9]+' $progressfile)
    gcloud compute --project=natcap-servers instances get-serial-port-output \
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

echo "Shutting down VM so we can image it."
# Computer setup is complete.  Shut it down so we can image it.
# Wait until the VM is completely shut down before imaging.
gcloud compute --project=natcap-servers instances stop $tempmachinename --zone=$zone
while true
do
    gcloud compute --project=natcap-servers \
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
    --family=windows-2008-r2

# now, delete the temporary VM without prompting for confirmation
echo "Deleting VM $tempmachinename"
gcloud compute instances delete --quiet $tempmachinename --zone=$zone



# TODO: update an existing template for jenkins windows slaves.

echo "Creating template from image " $templatename
gcloud compute instance-templates create $templatename \
    --boot-disk-auto-delete \
    --boot-disk-size=50GB \
    --boot-disk-type=pd-standard \
    --machine-type=n1-standard-2 \
    --metadata-from-file sysprep-specialize-script-ps1=install_windows_build_dependencies.ps1 \
    --region=$zone \
    --image-project=natcap-servers \
    --image=$templatename \
    --service-account=jenkins-build-cluster@natcap-servers.iam.gserviceaccount.com
echo "Done."
