#!/bin/bash

# curUser=$(whoami)
# if [[ ${curUser} == "root" ]]; then
#     echo "Can not assign root to file."
# elif [[ -z $(sudo ls /etc/sudoers.d/ | grep "terraform") ]] || [[ -z $(sudo cat /etc/sudoers.d/terraform | grep "​​​​​​${curUser} ALL=(root) NOPASSWD:/usr/bin/update-alternatives --config terraform") ]]; then
#     sudo bash -c 'echo "${curUser} ALL=(root) NOPASSWD:/usr/bin/update-alternatives --config terraform" >> /etc/sudoers.d/terraform'
# fi

chmod 755 ./*.sh

sudo cp ./TERRA.sh /bin/terra || exit 1