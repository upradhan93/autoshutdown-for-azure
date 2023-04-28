#!/bin/bash -ex

# Installs NICE DCV if users choose to enable it

# Flag to check if the license server address for NICE DCV is valid or not 
IS_VALID_ADDRESS=false
ADMIN_USERNAME=$1
RLM_LICENSE_SERVER=$2

if [[ $# -gt 1 ]]; then
    # If the input string contains '@', we assume it is a valid address
    if [[ ${RLM_LICENSE_SERVER} =~ "@" ]]; then
        IS_VALID_ADDRESS=true
    fi
fi

# Update apt and install NICE DCV
sudo apt install -y /usr/local/bin/nice-dcv-*-ubuntu2004-x86_64/nice-dcv-server_*.ubuntu2004.deb
sudo apt install -y /usr/local/bin/nice-dcv-*-ubuntu2004-x86_64/nice-dcv-web-*.ubuntu2004.deb
sudo usermod -aG video dcv

# use DCV authentication
sudo sed -i 's/#authentication="none"/authentication="system"/' /etc/dcv/dcv.conf

# configure automatic console sessions on service startup
sudo sed -i 's/^#owner.*$/owner='"${ADMIN_USERNAME}"'/' /etc/dcv/dcv.conf
sudo sed -i 's/^#create-session.*$/create-session = true/' /etc/dcv/dcv.conf

# configure max 1 session
sudo sed -i 's/^#max-concurrent-clients.*/max-concurrent-clients = 1/' /etc/dcv/dcv.conf

# enable file sharing
sudo sed -i 's/^#storage-root.*/storage-root="%home%"/' /etc/dcv/dcv.conf

# If user has input NICE DCV RLM server address then set this config in the dcv configuration file
if ${IS_VALID_ADDRESS} 
then
    sudo sed -i 's/^#license-file.*/license-file='"${RLM_LICENSE_SERVER}"'/' /etc/dcv/dcv.conf
fi

# Disable dcvserver for now. Will be enabled based on the user choice
sudo systemctl disable dcvserver   
