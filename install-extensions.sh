#!/bin/bash

# This script will be triggered as an ARM template extension to default matlab to point at license server, and define DDUX Env
# Example Use case: sh /usr/local/bin/install-extensions.sh variables('licenseServer') MATLAB:AZURE:V1 parameters('EnableNiceDCV') parameters('adminUsername') parameters('NiceDCVLicenseServer') 

license_server=$1
ddux_tag=$2
access_protocol=$3
admin_username=$4
rlm_license_server=$5

#startup accelerator. 
nohup /usr/local/matlab/bin/glnxa64/MATLABStartupAccelerator 64 /usr/local/matlab /usr/local/etc/msa/msa.ini /tmp/startup_accelerator.log &> /dev/null  &

if [ "${license_server}" != "mhlm" ]; then
    # remove the online licensing default
    sudo rm -f /usr/local/matlab/licenses/license_info.xml

    # default matlab to point at license server port@server
    echo "export MLM_LICENSE_FILE=${license_server}" | sudo tee -a /etc/profile.d/mlmlicensefile.sh
fi

# define DDUX Env
echo "export MW_CONTEXT_TAGS=${ddux_tag}" > /etc/profile.d/dduxvars.sh

if [ "${access_protocol}" = "Yes" ]; then
    # Configure NICE DCV in the VM
# Install NICE DCV, if another process is using apt wait for it to complete (300 seconds) before timing out
sudo apt install -o DPkg::Lock::Timeout=300 -y /usr/local/bin/nice-dcv-*-ubuntu2004-x86_64/nice-dcv-server_*.ubuntu2004.deb /usr/local/bin/nice-dcv-*-ubuntu2004-x86_64/nice-dcv-web-*.ubuntu2004.deb
sudo usermod -aG video dcv

# use DCV authentication
sudo sed -i 's/#authentication="none"/authentication="system"/' /etc/dcv/dcv.conf

# configure automatic console sessions on service startup
sudo sed -i 's/^#owner.*$/owner='"${admin_username}"'/' /etc/dcv/dcv.conf
sudo sed -i 's/^#create-session.*$/create-session = true/' /etc/dcv/dcv.conf

# configure max 1 session
sudo sed -i 's/^#max-concurrent-clients.*/max-concurrent-clients = 1/' /etc/dcv/dcv.conf

# enable file sharing
sudo sed -i 's/^#storage-root.*/storage-root="%home%"/' /etc/dcv/dcv.conf
# Disable dcvserver for now. Will be enabled based on the user choice
sudo systemctl disable dcvserver
fi

# Start desktop
/usr/local/bin/start-desktop.sh ${admin_username} ${access_protocol}

nohup sudo unattended-upgrade -d
