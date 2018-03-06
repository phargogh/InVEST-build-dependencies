#!/usr/bin/env bash



rev=`hg log -r. --template="r{rev}-c{date(date, '%Y%m%d')}-{node|short}"`
templatename="jenkins-win2008r2-$rev"
tempmachinename=$templatename-setupinprogress
zone=us-west1-a

#gcloud compute instance-templates create $templatename \
#    --boot-disk-auto-delete \
#    --boot-disk-size=50GB \
#    --boot-disk-type=pd-standard \
#    --machine-type=n1-standard-2 \
#    --metadata-from-file sysprep-specialize-script-ps1=install_windows_build_dependencies.ps1 \
#    --region=$zone \
#    --image-project=windows-cloud \
#    --image=windows-server-2008-r2-dc-v20180213 \
#    --service-account=jenkins-build-cluster@natcap-servers.iam.gserviceaccount.com

# create an instance with the target setup script
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
echo "    $ gcloud compute --project=natcap-servers get-serial-port-output $tempmachinename --zone=$zone"
while true
do
    gcloud compute --project=natcap-servers \
        instances get-serial-port-output \
        $tempmachinename --zone=us-west1-a | tail -n 20 | grep "Activation successful"
    if [ $? -eq 0 ]
    then
        # computer setup is complete, wait until the machine is completely shut down
        # before creating the new machine image.
        while true
        do
            gcloud compute --project=natcap-servers \
                instances describe $tempmachinename | grep status | grep TERMINATED
            if [ $? -eq 0 ]
            then
                gcloud compute images create $templatename \
                    --source-disk=$tempmachinename \
                    --source-disk-zone=$zone \
                    --family=windows-2008-r2

                # now, delete the temporary VM
                gcloud compute instances delete $tempmachinename --zone=$zone
                break
            else
                sleep 2
            fi
        done
        break
    else
        # computer setup is still in progress 
        sleep 2
    fi
done


