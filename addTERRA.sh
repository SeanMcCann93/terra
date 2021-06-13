#!/bin/bash

echo "ALL​​​​​​​​​​ ALL=(root) NOPASSWD:/usr/bin/update-alternatives --config terraform" >> sudo /etc/sudoers.d/terraform

chmod 755 ./*.sh

sudo cp ./TERRA.sh /bin/terra || exit 1