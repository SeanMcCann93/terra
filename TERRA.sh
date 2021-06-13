#!/bin/bash

# Developed by Sean McCann 2021. This has been designed to enable users the ability to switch between Terraform versions with ease.

TERRAINPUT1=${1}
VERSION=${2}
forceSet="false"

terraLogo() {
    printf "\n__________________________________________    _____ \n\\__    ___/\\_   _____/\\______   \\______   \\  /  _  \\ \n  |    |    |    __)_  |       _/|       _/ /  /_\\  \\ \n  |    |    |        \\ |    |   \\|    |   \\/    |    \\ \n  |____|   /_______  / |____|_  /|____|_  /\\____|__  / \n                   \\/         \\/        \\/         \\/ \n\n"
}

installUnzip() {
    printf "*** Install Unzip ~ START ***\n\n"
    sudo apt install unzip -y
    printf "\n*** Install Unzip ~ END ***\n\n"
}

terraList() {
    TERRALIST=($(sudo update-alternatives --list terraform))
    TERRALISTCOUNT=$(update-alternatives --list terraform | wc -l)
}

terraPriority() {
    if [[ ${VERSION##*.} -lt 10 ]]; then
        VER=${VERSION#*.}
        PRIORITY=$(echo "${VER%.*}0${VERSION##*.}")
    else
        PRIORITY=$(echo "${VERSION#*.}" | tr -d .)
    fi
    if [ ${VERSION%%.*} -gt 0 ]; then
        PRIORITY=$(echo "${VERSION%%.*}${PRIORITY}")
    fi
}

terraTest() {
    if [[ -z $(ls /usr/local/ | grep "terraform") ]]; then
        echo "make 'terraform' dirirectory to store versions."
        sudo mkdir /usr/local/terraform
    fi
    if [[ -z $(update-alternatives --list terraform | grep "${VERSION}") ]]; then
        if [[ -z $(ls /usr/local/terraform/ | grep "${VERSION}") ]]; then
            terraAdd
        else
            terraInstall
        fi
    fi
}

terraAdd() {
    echo
    curl -O https://releases.hashicorp.com/terraform/"${VERSION}"/terraform_"${VERSION}"_linux_amd64.zip || exit 1
    echo 
    curl -O https://releases.hashicorp.com/terraform/"${VERSION}"/terraform_"${VERSION}"_SHA256SUMS || exit 1
    echo
    TERRA_SHA256=$(cat terraform_"${VERSION}"_SHA256SUMS | grep -w terraform_"${VERSION}"_linux_amd64.zip)
    echo "${TERRA_SHA256}" | sha256sum -c - || exit 1
    echo
    sudo mkdir -p /usr/local/terraform/"${VERSION}"
    if [[ "$(unzip -v 2>/dev/null)" = "" ]]; then
        installUnzip
    fi
    sudo unzip terraform_"${VERSION}"_linux_amd64.zip -d /usr/local/terraform/"${VERSION}"/ || exit 1
    sudo rm -rf terraform_"${VERSION}"_linux_amd64.zip || exit 1
    sudo rm -rf terraform_"${VERSION}"_SHA256SUMS || exit 1
    terraInstall
}

terraRemove() {
    terraUninstall
    sudo rm -rf /usr/local/terraform/${VERSION}*
}

terraInstall() {
    terraPriority
    sudo update-alternatives --install /usr/local/bin/terraform terraform /usr/local/terraform/"${VERSION}"/terraform "${PRIORITY}" || exit 1
    echo
}

terraUninstall() {
    if [[ $(terraform --version | grep "${VERSION}") == "${VERSION}" ]]; then
        forceSet="true"
        terraSet
    fi
    sudo update-alternatives --remove terraform /usr/local/terraform/${VERSION}/terraform
}

terraSet() {
    if [[ ${forceSet} == "true" ]]; then
        echo "0" | sudo update-alternatives --config terraform  &> /dev/null
        forceSet="false"
    else
        terraList
        TERRALISTCOUNT=$((($TERRALISTCOUNT - 1)))
        for (( c=0; c<=$TERRALISTCOUNT; c++ ))
        do
            if [[ ${TERRALIST[${c}]} == *"/${VERSION}/"* ]]; then
                TERRALISTCOUNT="$(((${c} + 1)))"
                echo "$TERRALISTCOUNT" | sudo update-alternatives --config terraform  &> /dev/null
                terraform --version
                break;
            fi
        done
    fi
}

terraHelp() {
    printf "\n-----------------------------\nHow to use this application.\n-----------------------------\n\nThis application has been designed to enable the user to switch between Terraform 'VERSION's automaticly without the need to enter into the terminal manualy.\n\nTo take advantage of this feature, it is designed to take commands in the following formate.\n\n    terra [function] [version]\n\nPlease Note: The Version must be supplied like the following example; '0.15.5'.\n\n"
    printf "[functions]\n\n    '-s' ~ Set Terraform version.\n\n    '-l' ~ List all Terraform version paths.\n\n    '-a' ~ Add Terraform version.\n\n    '-r' ~ Remove Terraform version.\n\n    '-h' ~ Get help with Terraform Tool.\n\n"
}

if [[ -z $TERRAINPUT1 ]]; then
    terraLogo
    LOGOP="true"
    printf "\n Hi, Please state what you would like to do.\n\n    '-s' ~ Set Terraform version.\n\n    '-l' ~ List all Terraform version paths.\n\n    '-a' ~ Add Terraform version.\n\n    '-r' ~ Remove Terraform version.\n\n    '-h' ~ Get help with Terraform Tool.\n\n"
    read -p "Please enter the number related to your request: " TERRAINPUT1
    echo
fi

if [[ -z $VERSION ]] && [[ $TERRAINPUT1 != "-h" ]] && [[ $TERRAINPUT1 != "help" ]] && [[ $TERRAINPUT1 != "-l" ]]; then
    if [[ ${LOGOP} != "true" ]]; then
        terraLogo
        LOGOP="true"
    fi
    printf "\n List of all installed Version paths.\n\n"
    update-alternatives --list terraform
    printf "\n Please enter the Terraform version.\n\n"
    read -p "Version: " VERSION
    echo
fi

if [[ ${TERRAINPUT1} == "-s" ]]; then
    terraTest
    terraSet
elif [[ ${TERRAINPUT1} == "-a" ]]; then
    terraTest
elif [[ ${TERRAINPUT1} == "-r" ]]; then
    terraRemove
elif [[ ${TERRAINPUT1} == "-l" ]]; then
    if [[ ${LOGOP} != "true" ]]; then
        terraLogo
        LOGOP="true"
    fi
    sudo update-alternatives --list terraform
elif [[ ${TERRAINPUT1} == "-h" ]] || [[ $TERRAINPUT1 == "help" ]]; then
    if [[ ${LOGOP} != "true" ]]; then
        terraLogo
        LOGOP="true"
    fi
    terraHelp
else
    echo "Unable to perform an action using "${TERRAINPUT1}""
fi