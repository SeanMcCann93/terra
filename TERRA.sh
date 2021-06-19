#!/bin/bash

# terraDebug="true"
terraSaved=${2}
dirList=($(ls /usr/local/terraform/))

# *** General *********************************

terraLogo() {
    if [[ ${TERRALogoDisp} != "true" ]]; then
        TERRALogoDisp="true"
        cat <<EOF

    __________________________________________    _____ 
    \__    ___/\_   _____/\______   \______   \  /  _  \   
      |    |    |    __)_  |       _/|       _/ /  /_\  \  
      |    |    |        \ |    |   \|    |   \/    |    \ 
      |____|   /_______  / |____|_  /|____|_  /\____|__  / 
                       \/         \/        \/         \/  

EOF
    else
        echo
    fi
}

terraHelp() {
    terraPrint Pass "Help" "Bellow is a list of actionable commands. Incorperate them with terra to perform quick actions.\n"
    printf "terra "
    terraPrint Active "Action" '[\033[0;33mVersion\033[0m]\n'
    terraPrint Active -s "or --set is to make the desired version active. \033[0;33mVersion\033[0m can be included.\n"
    terraPrint Active -a "or --add is to install the desired version. \033[0;33mVersion\033[0m can be included.\n"
    terraPrint Active -d "or --del is to fully remove the desired version. \033[0;33mVersion\033[0m can be included.\n"
    terraPrint Active -l "or --list is used to display all versions currently available.\n"
}

terraLeave() {
    echo
    exit 1
}

# *** General ~ END *********************************
# *** Debug *********************************

terraPrint() {
    if [[ $terraDebug == "true" ]]; then
        terraFlag "${1}" "[${2}]"
        terraFlag None " ${3} \n"
    fi
    if [[ ${4} == "leave" ]]; then
        terraLeave;
    fi
}

terraFlag() {
    if [[ ${1} == "Fail" ]]; then
        printf "\033[0;31m${2}" #Red
    elif [[ ${1} == "Pass" ]]; then
        printf "\033[0;32m${2}" # Green
    elif [[ ${1} == "Change" ]]; then
        printf "\033[0;33m${2}" # Yellow
    elif [[ ${1} == "Unchange" ]]; then
        printf "\033[0;35m${2}" # Purple
    elif [[ ${1} == "Active" ]]; then
        printf "\033[0;36m${2}" #Cyan
    else
        printf "\033[0m${2}" # Standard
    fi
}

# *** Debug ~ END *********************************
# *** Installs *********************************

installUnzip() {
    terraPrint Change Unzip "Installing.\n"
    sudo apt install unzip -y || terraPrint Fail "InstallFailed" "Unzip was unsuccessful." leave
    echo
    terraPrint Pass Progress "unzip install successful!.\n"
}

# *** Installs ~ END *********************************
# *** Create *********************************

terraAdd() {
    terraPrint Change Add "Terraform ${1}.\n"

    terraDownload "${1}" "linux_amd64.zip"
    terraDownload "${1}" "SHA256SUMS"

    sha256sum -c --ignore-missing --status "terraform_${1}_SHA256SUMS" || terraPrint Fail sha256sum "Failed." leave
    terraPrint Pass sha256sum "OK!\n"

    if [[ ! -d /usr/local/terraform/${1} ]]; then
        terraPrint Change Create "/usr/local/terraform/${1} directory.\n"
        sudo mkdir -p "/usr/local/terraform/${1}"
    else
        terraPrint Fail Found "/usr/local/terraform/${1} directory."
        while true; do
                if [[ ${2} == "-y" ]]; then
                    yn="y"
                else
                    read -p "Do you wish to overwrite this directory (Y/N)? " yn # Optional Pull of git changes
                fi
                case $yn in
                    [Yy]* ) 
                        echo
                        terraPrint Change Overwite "/usr/local/terraform/${1} directory.\n"
                        break;;
                    [Nn]* )
                        echo
                        sudo rm -rf "terraform_${1}_linux_amd64.zip" || terraPrint Fail sha256sum "Failed.\n"
                        sudo rm -rf "terraform_${1}_SHA256SUMS" || terraPrint Fail sha256sum "Failed.\n"
                        terraPrint Fail Stopped "Overwrite prevented and files removed." leave;;
                    * ) echo "Please answer with 'y' or 'n'.";;
                esac
            done
    fi

    if [[ "$(unzip -v 2>/dev/null)" = "" ]]; then
        terraPrint Fail Unzip "Not found, forcing install to release .zip packages.\n"
        installUnzip
    else
        terraPrint Pass Unzip "Installed!\n"
    fi

    terraFlag Change
    sudo unzip -o "terraform_${1}_linux_amd64.zip" -d "/usr/local/terraform/${1}/" && printf "\n" || terraPrint Fail Unzip "Failed to extract files." leave
    sudo rm -rf "terraform_${1}_linux_amd64.zip" || terraPrint Fail sha256sum "Failed." leave
    sudo rm -rf "terraform_${1}_SHA256SUMS" || terraPrint Fail sha256sum "Failed." leave
    terraPrint Pass Progress "Terraform ${1} add successful!\n"
    terraInstall "${1}"
}

terraDownload() {
    terraPrint Change Download "Terraform ${2}.\n"
    terraFlag Change
    curl -SO --fail "https://releases.hashicorp.com/terraform/${1}/terraform_${1}_${2}" || terraPrint Fail Failed "Unable to download ${2} File." leave
    terraFlag None "\n"
    terraPrint Pass Progress "Terraform ${2} downloaded successful!\n"
}

terraInstall() {
    terraPrint Change Install "Terraform '${1}'.\n"
    terraPriority "${1}"
    terraFlag Change
    sudo update-alternatives --install /usr/local/bin/terraform terraform /usr/local/terraform/"${1}"/terraform "${PRIORITY}" || terraPrint Fail Failed "Unable to Install Terraform ${1}." leave
    echo
    terraPrint Pass Progress "Terraform '${1}' install successfull.\n"
}

terraPriority() {
    terraPrint Change Priority "Resolving ${1}.\n"
    IFS='.'
    for i in $1; do
        VAR+=($i)
    done
    IFS=' '
    if [[ ${VAR[1]} -lt 10 ]]; then
        terraPrint Change Priority "Version *.here.* found to be lower than 2 values.\n"
        VAR[1]="0${VAR[1]}"
    fi

    if [[ ${VAR[2]} -lt 10 ]]; then
        terraPrint Change Priority "Version *.*.here found to be lower than 2 values.\n"
        VAR[2]="0${VAR[2]}"
    fi

    if [[ ${VAR[0]} -gt 0 ]]; then
        terraPrint Change Priority "Version here.*.* found to be lower than 2 values.\n"
        PRIORITY="${VAR[0]}${VAR[1]}${VAR[2]}"
    else
        PRIORITY="${VAR[1]}${VAR[2]}"
    fi
    terraPrint Pass Progress "Priority resolved to ${PRIORITY}.\n"
}

# *** Create ~ END *********************************
# *** Read *********************************

terraList() {
    terraPrint Unchange List "All Terraform versions.\n"
    dirNum=$(ls /usr/local/terraform/ | wc -l)
    dirNum=$((($dirNum - 1)))
    for (( c=0; c<=$dirNum; c++ )); do
            if [[ $(terraform --version | grep "${dirList[${c}]}") ]]; then
                terraFlag Active "*${dirList[${c}]}"
                terraFlag None
            else
                printf "${dirList[${c}]}"
            fi
            if [[ $c != $dirNum ]]; then
                printf "\n"
            else
                printf "\n\n"
            fi
    done
    terraPrint Pass Progress "Terraform list successful!.\n"
}

# *** Read ~ END *********************************
# *** update *********************************

terraSet() {
    if [[ ${1} == "forceUninstall" ]]; then
        terraPrint Change Set "Force auto.\n"
        terraFlag Change
        update-alternatives --auto terraform
        terraPrint Pass Progress "Auto set successful!\n"
    else
        if [[ ! -d /usr/local/terraform/${1} ]]; then
            terraAdd "${1}"
            setFlag="Change"
        elif [[ -z $(update-alternatives --list terraform | grep "${terraSaved}") ]]; then
            terraInstall "${1}"
            setFlag="Unchange"
        elif [[ $(terraform --version | grep "${terraSaved}") ]]; then
            setFlag="Active"
        else
            setFlag="Pass"
        fi
        terraPrint "${setFlag}" Set "Terraform '${1}'.\n"
        sudo update-alternatives --set terraform "/usr/local/terraform/${1}/terraform" &> /dev/null || terraPrint Fail Set "To ${1} was not Successful." leave
        terraPrint Pass Progress "Terraform ${1} set successful!\n"
    fi
}

# *** Update ~ END *********************************
# *** Delete *********************************

terraDelete() {
    terraPrint Change Delete "Terraform ${1}.\n"
    if [[ $(update-alternatives --list terraform | grep "${terraSaved}") ]]; then
        terraUninstall "${1}"
    fi
    sudo rm -rf "/usr/local/terraform/${1}" || terraPrint Fail Delete "${1} Failed." leave
    terraPrint Pass Progress "Terraform ${1} delete successful!.\n"
}

terraUninstall() {
    terraPrint Change Uninstall "Terraform ${1}.\n"
    if [[ $(terraform --version | grep "${terraSaved}" ) ]]; then
        terraSet "forceUninstall"
    fi
    terraFlag Fail
    sudo update-alternatives --remove terraform "/usr/local/terraform/${1}/terraform" || terraPrint Fail Failed "Unable to remove ${1} version." leave
    terraPrint Pass Progress "Terraform ${1} uninstall successful!\n"
}

# *** Delete ~ END *********************************

if [[ ! -d /usr/local/terraform ]]; then
    terraPrint Change Create "'/usr/local/terraform' directory to store Terraform versions.\n"
    sudo mkdir /usr/local/terraform
    terraPrint Pass Progress "'/usr/local/terraform' directory create successful!\n"
fi

if [[ $1 == "-s" ]] || [[ $1 == "--set" ]]; then
    if [[ -z $terraSaved ]]; then
        terraPrint Fail Version "not found.\n"
        terraLogo
        while true; do
            read -p "Please enter the Terraform version: " terraSaved
            case $terraSaved in
                '' ) 
                    echo "A value must exist!";;
                help )
                    printf "\nAvailable versions to set:\n\n"
                    terraList
                    printf "To Set a version it must first be installed. A list of\nversions that can be installed are found at:\n\n    https://releases.hashicorp.com/terraform    \n\nFind the desired version and input its version number here.\n Example: '0.00.00'\n\n";;
                * )
                    break;;
            esac
        done
    fi
    terraSet "$terraSaved"
elif [[ $1 == "-a" ]] || [[ $1 == "--add" ]]; then
    if [[ -z $terraSaved ]]; then
        terraPrint Fail Version "not found.\n"
        terraLogo
        while true; do
            read -p "Please enter the Terraform version: " terraSaved
            case $terraSaved in
                '' ) 
                    echo "A value must exist!";;
                help )
                    printf "\nTo take advantage of this application it helps to know what\nversions are available. A list of versions can be found at:\n\n    https://releases.hashicorp.com/terraform    \n\nFind the desired version and input its version number here.\n Example: '0.00.00'\n\n";;
                * )
                    break;;
            esac
        done
    fi
    terraAdd "$terraSaved" "$3"
elif [[ $1 == "-d" ]] || [[ $1 == "--del" ]]; then
    if [[ -z $terraSaved ]]; then
        terraPrint Fail Version "not found.\n"
        terraLogo
        while true; do
            read -p "Please enter the Terraform version: " terraSaved
            case $terraSaved in
                '' ) 
                    echo "A value must exist!";;
                help )
                    printf "\nPlease see bellow a list of versions available to delete.\n\n"
                    terraList;;
                * )
                    break;;
            esac
        done
    fi
    terraDelete "$terraSaved"
elif [[ $1 == "-l" ]] || [[ $1 == "--list" ]]; then
    terraLogo
    terraList
elif [[ $1 == "-h" ]] || [[ $1 == "--help" ]]; then
    terraLogo
    terraHelp
else
    terraPrint Fail Action "not found.\n"
    terraLogo
    printf "Welcome to terra, this tool has been developed to enable users a\nclean way to navigate Terraform versions within a Linux system.\n\nIf you wish to take advantage of this tool, please use the\n\033[0;32m[-h]\033[0m or --help extension to display all commands available.\n\n"
fi