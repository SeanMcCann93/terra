#!/bin/bash

curUser=$(whoami)
if [[ -z $(sudo ls /etc/sudoers.d/ | grep "terraform") ]] || [[ -z $(sudo cat /etc/sudoers.d/terraform | grep "​​​​​​${currentUser} ALL=(root) NOPASSWD:/usr/bin/update-alternatives --config terraform") ]]; then
    sudo bash -c 'echo "${currentUser} ALL=(root) NOPASSWD:/usr/bin/update-alternatives --config terraform" >> /etc/sudoers.d/terraform'
fi

chmod 755 ./*.sh

sudo cp ./TERRA.sh /bin/terra || exit 1