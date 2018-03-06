#!/usr/bin/env bash



rev=`hg log -r. --template="r{rev}-c{date(date, '%Y%m%d')}-{node|short}"`
templatename="jenkins-win2008r2-$rev"
tempmachinename=$templatename-setupinprogress

#gcloud compute instance-templates create $templatename \
#    --boot-disk-auto-delete \
#    --boot-disk-size=50GB \
#    --boot-disk-type=pd-standard \
#    --machine-type=n1-standard-2 \
#    --metadata-from-file sysprep-specialize-script-ps1=install_windows_build_dependencies.ps1 \
#    --region=us-west1-a \
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
    --zone=us-west1-a \
    --image-project=windows-cloud \
    --image=windows-server-2008-r2-dc-v20180213 \
    --service-account=jenkins-build-cluster@natcap-servers.iam.gserviceaccount.com


# shut down the computer once setup finishes

# create an image of the disk created by the new instance command.

