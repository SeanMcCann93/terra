#!/bin/bash

# terraDebug="true"
terraSaved=${2}
dirList=($(ls /usr/local/terraform/))

# *** General *********************************

terraLogo() {
    if [[ ${terraLogoDisp} != "true" ]]; then
        terraDebugTool Change "LOGO TASK" "Change 'terraLogoDisp' Variable to true. This will prevent the Logo being produced again.\n"
        terraLogoDisp="true"
        cat <<EOF

    __________________________________________    _____ 
    \__    ___/\_   _____/\______   \______   \  /  _  \   
      |    |    |    __)_  |       _/|       _/ /  /_\  \  
      |    |    |        \ |    |   \|    |   \/    |    \ 
      |____|   /_______  / |____|_  /|____|_  /\____|__  / 
                       \/         \/        \/         \/  

EOF
    else
        terraDebugTool Unchange "LOGO TASK" "'terraLogoDisp' Variable is true, Skip logo display.\n"
    fi
}

terraHelp() {
    terraFlag Pass "[Help] "
    terraFlag None "Bellow is a list of actionable commands. Incorperate them with terra to perform quick actions.\n\n"
    printf "terra "
    terraFlag Active "[Action] "
    terraFlag None "\033[0;33m[Version]\033[0m\n\n"
    terraFlag Active "[-s} "
    terraFlag None "or --set is to make the desired version active. \033[0;33mVersion\033[0m can be included.\n\n"
    terraFlag Active "[-a] " 
    terraFlag None "or --add is to install the desired version. \033[0;33mVersion\033[0m can be included.\n\n"
    terraFlag Active "[-d] " 
    terraFlag None "or --del is to fully remove the desired version. \033[0;33mVersion\033[0m can be included.\n\n"
    terraFlag Active "[-l] " 
    terraFlag None "or --list is used to display all versions currently available.\n\n"
}

terraLeave() {
    echo
    exit 1
}

# *** General ~ END *********************************
# *** Debug *********************************

terraDebugTool() {
    if [[ $terraDebug == "true" ]] || [[ $1 == "ERROR" ]]; then
        terraFlag "${1}" "[${2}]"
        terraFlag None " ${3} \n"
    fi
    if [[ ${4} == "leave" ]]; then
        terraLeave;
    fi
}

terraFlag() {
    if [[ ${1} == "ERROR" ]]; then
        printf "\e[1;31m${2}" #Red
    elif [[ ${1} == "Pass" ]]; then
        printf "\033[0;32m${2}" # Green
    elif [[ ${1} == "Fail" ]]; then
        printf "\e[0;31m${2}" # Red
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
    terraDebugTool Change "START TASK" "Installing Unzip.\n"
    sudo apt install unzip -y || terraDebugTool ERROR "InstallFailed" "Unzip was unsuccessful." leave
    echo
    terraDebugTool Pass "END TASK" "Install Unzip successful!.\n"
}

# *** Installs ~ END *********************************
# *** Create *********************************

terraAdd() {
    terraDebugTool Change "START TASK" "Add Terraform ${1}.\n"

    terraDownload "${1}" "linux_amd64.zip"
    terraDownload "${1}" "SHA256SUMS"

    sha256sum -c --ignore-missing --status "terraform_${1}_SHA256SUMS" || terraDebugTool ERROR "CHECK TASK" "Sha256sum did not match!" leave
    terraDebugTool Pass "CHECK TASK" "Sha256sum pessed.\n"

    if [[ ! -d /usr/local/terraform/${1} ]]; then
        terraDebugTool Change "CREATE TASK" "/usr/local/terraform/${1} directory.\n"
        sudo mkdir -p "/usr/local/terraform/${1}"
    else
        terraDebugTool Unchange "CREATE TASK" "Directory at /usr/local/terraform/${1} found.\n"
        while true; do
                if [[ ${2} == "-y" ]]; then
                    yn="y"
                    terraDebugTool Pass "CREATE TASK" "Prompt to overwrite skipped.\n"
                else
                    read -p "Do you wish to overwrite this directory (Y/N)? " yn # Optional Pull of git changes
                fi
                case $yn in
                    [Yy]* ) 
                        echo
                        terraDebugTool Change "CREATE TASK" "Set to overwite /usr/local/terraform/${1} directory.\n"
                        break;;
                    [Nn]* )
                        echo
                        sudo rm -rf "terraform_${1}_linux_amd64.zip" || terraDebugTool ERROR "REMOVE TASK" "Failed to remove 'terraform_${1}_linux_amd64.zip'.\n"
                        sudo rm -rf "terraform_${1}_SHA256SUMS" || terraDebugTool ERROR "REMOVE TASK" "Failed to remove 'terraform_${1}__SHA256SUMS'.\n"
                        terraDebugTool ERROR STOPPED "Overwrite prevented by user." leave;;
                    * ) echo "Please answer with 'y' or 'n'.";;
                esac
            done
    fi

    if [[ "$(unzip -v 2>/dev/null)" = "" ]]; then
        terraDebugTool Fail "REQUIRED" "Unzip not found, forcing install to release .zip packages.\n"
        installUnzip
    else
        terraDebugTool Pass "REQUIRED" "Unzip installed.\n"
    fi

    terraDebugTool Change "UNZIP TASK" "Extract files from terraform_${1}_linux_amd64.zip.\n"
    terraFlag Change
    sudo unzip -o "terraform_${1}_linux_amd64.zip" -d "/usr/local/terraform/${1}/" 1> /dev/null || terraDebugTool FERRORail "UNZIP TASK" "Failed to extract files." leave
    terraDebugTool Pass "UNZIP TASK" "Files from terraform_${1}_linux_amd64.zip extraction successful.\n"

    terraDebugTool Change "REMOVE TASK" "Remove unwanted files.\n"
    terraFlag Change
    sudo rm -rf "terraform_${1}_linux_amd64.zip" || terraDebugTool ERROR sha256sum "Failed." leave
    sudo rm -rf "terraform_${1}_SHA256SUMS" || terraDebugTool ERROR sha256sum "Failed." leave
    terraDebugTool Pass "REMOVE TASK" "Remove files successful.\n"

    terraDebugTool Pass "END TASK" "Add Terraform ${1} successful.\n"
    terraInstall "${1}"
}

terraDownload() {
    terraDebugTool Change "START TASK" "Download Terraform ${2}.\n"
    terraFlag ERROR
    curl -sSO --fail "https://releases.hashicorp.com/terraform/${1}/terraform_${1}_${2}" || terraDebugTool ERROR "FAILED TASK" "Unable to download ${2} File." leave
    terraDebugTool Pass "END TASK" "Downloaded Terraform ${2} successful.\n"
}

terraInstall() {
    terraDebugTool Change "START TASK" "Install Terraform ${1}.\n"
    
    terraPriority "${1}"
    terraDebugTool Change "INSTALL TASK" "Applying Terraform ${1} to activatable stack.\n"
    terraFlag Change
    sudo update-alternatives --install /usr/local/bin/terraform terraform /usr/local/terraform/"${1}"/terraform "${PRIORITY}" || terraDebugTool ERROR "FAILED TASK" "Unable to install Terraform ${1}." leave
    terraDebugTool Pass "END TASK" "Install Terraform ${1} successful.\n"
}

terraPriority() {
    terraDebugTool Change "START TASK" "Resolving ${1} into priority value.\n"

    terraDebugTool Change "PRIORITY TASK" "Isolate version digits into array to later be recompiled.\n"
    IFS='.'
    for i in $1; do
        VAR+=($i)
    done
    IFS=' '
    terraDebugTool Pass "PRIORITY TASK" "Digits isolated into Release[${VAR[0]}] Bata[${VAR[1]}] Alpha[${VAR[2]}] versions.\n"

    if [[ ${VAR[2]} -lt 10 ]]; then
        terraDebugTool Change "PRIORITY TASK" "Alpha version is not is not in double digit values.\n"
        VAR[2]="0${VAR[2]}"
    fi
    
    if [[ ${VAR[1]} -lt 10 ]]; then
        terraDebugTool Change "PRIORITY TASK" "Beta version is not is not in double digit values.\n"
        VAR[1]="0${VAR[1]}"
    fi

    if [[ ${VAR[0]} -gt 0 ]]; then
        terraDebugTool Change "PRIORITY TASK" "Set priority with release version.\n"
        PRIORITY="${VAR[0]}${VAR[1]}${VAR[2]}"
    else
        terraDebugTool Change "PRIORITY TASK" "Set priority with no release version.\n"
        PRIORITY="${VAR[1]}${VAR[2]}"
    fi
    terraDebugTool Pass "PRIORITY TASK" "Priority resolved to ${PRIORITY}.\n"

    terraDebugTool Change "END TASK" "Priority resolve successful.\n"
}

# *** Create ~ END *********************************
# *** Read *********************************

terraList() {
    terraDebugTool Change "START TASK" "Gather a list of available versions.\n"

    terraDebugTool Unchange "LIST TASK" "Get number of files in directory.\n"
    dirNum=$(ls /usr/local/terraform/ | wc -l)
    terraDebugTool Change "LIST TASK" "Reduce value.\n"
    dirNum=$((($dirNum - 1)))

    terraDebugTool Change "LIST TASK" "Print all versions and highlight active.\n"
    for (( c=0; c<=$dirNum; c++ )); do
            if [[ $(terraform --version -json | grep "${dirList[${c}]}") ]]; then
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

    terraDebugTool Pass "END TASK" "Terraform list successful.\n"
}

terraVersion() {
    terraDebugTool Change "START TASK" "Dispaly terraform --version output.\n"
    terraform --version
    terraDebugTool Pass "END TASK" "Dispaly version output successful.\n"
}

# *** Read ~ END *********************************
# *** update *********************************

terraSet() {
    terraDebugTool Change "START TASK" "Set Terraform ${1}.\n"
    if [[ ${1} == "auto" ]]; then
        terraDebugTool Change "SET TASK" "Set Terraform to ${1}.\n"
        terraFlag Change
        sudo update-alternatives --auto terraform
    else
        if [[ ! -d /usr/local/terraform/${1} ]]; then
            terraDebugTool Fail "SET TASK" "Version is not installed.\n"
            terraAdd "${1}"
            setFlag="Change"
        elif [[ -z $(update-alternatives --list terraform | grep "${terraSaved}") ]]; then
            terraDebugTool Fail "SET TASK" "Version directory found but not installed.\n"
            terraInstall "${1}"
            setFlag="Change"
        elif [[ $(terraform --version -json | grep "${terraSaved}") ]]; then
            terraDebugTool Active "SET TASK" "Version is already active.\n"
            setFlag="Unchange"
        else
            setFlag="Pass"
        fi

        if [[  $setFlag !=  "Unchange" ]]; then
            terraDebugTool "${setFlag}" "SET TASK" "Set to Terraform ${1}.\n"
            sudo update-alternatives --set terraform "/usr/local/terraform/${1}/terraform" &> /dev/null || terraDebugTool ERROR "SET TASK" "To ${1} was not Successful." leave
        fi
    fi
    if [[  $2 == -v  ]] || [[  $2 == --version  ]]; then
        terraDebugTool Unchange "SET TASK" "Version request found.\n"
        terraVersion
    fi
    terraDebugTool Pass "END TASK" "Set Terraform ${1} successful.\n"
}

# *** Update ~ END *********************************
# *** Delete *********************************

terraDelete() {
    terraDebugTool Pass "START TASK" "Delete Terraform ${1}.\n"
    
    if [[ $(update-alternatives --list terraform | grep "${terraSaved}") ]]; then
        terraDebugTool Fail "DELETE TASK" "Terraform ${1} is active in version stack.\n"
        terraUninstall "${1}"
    fi

    terraDebugTool Change "DELETE TASK" "Delete /usr/local/terraform/${1} directory and its contents.\n"
    sudo rm -rf "/usr/local/terraform/${1}" || terraDebugTool ERROR "DELETE TASK" "Unable to delete /usr/local/terraform/${1} for system." leave

    terraDebugTool Pass "END TASK" "Terraform ${1} delete successful.\n"
}

terraUninstall() {
    terraDebugTool Change "START TASK" "uninstall Terraform ${1}.\n"
    
    terraDebugTool Change "UNINSTALL TASK" "Uninstall Terraform ${1} from version stack.\n"
    if [[ $(terraform --version | grep "${terraSaved}" ) ]]; then
        terraDebugTool Fail "UNINSTALL TASK" "Terraform ${1} is active.\n"
        terraSet "auto"
    fi
    terraFlag Change
    sudo update-alternatives --remove terraform "/usr/local/terraform/${1}/terraform" || terraDebugTool ERROR "UNINSTALL TASK" "Terraform ${1} version failed to uninstall." leave

    terraDebugTool Pass "END TASK" "Terraform ${1} uninstall successful!.\n"
}

# *** Delete ~ END *********************************

terraDebugTool Change "START TERRA" "Welcome\n"

if [[ ! -d /usr/local/terraform ]]; then
    terraDebugTool Change "SETUP TERRA" "'/usr/local/terraform' directory created to store Terraform versions.\n"
    sudo mkdir /usr/local/terraform
    terraDebugTool Pass "SETUP TERRA" "'/usr/local/terraform' directory create successful!\n"
fi

if [[ $1 == "-s" ]] || [[ $1 == "--set" ]]; then
    terraDebugTool Pass "TERRA ACTION" "${1} used.\n"
    if [[ -z $terraSaved ]]; then
        terraDebugTool Unchange "TERRA SET" "Version value not present.\n"
        terraLogo
        while true; do
            read -p "Please enter the Terraform version: " terraSaved
            case $terraSaved in
                '' ) 
                    terraDebugTool Unchange "TERRA SET" "Value entered is '${terraSaved}'.\n"
                    echo "A value must exist!";;
                help )
                    terraDebugTool Unchange "TERRA SET" "Display '${terraSaved}' for terraSet.\n"
                    printf "\nAvailable versions to set:\n\n"
                    terraList
                    printf "To Set a version it must first be installed. A list of\nversions that can be installed are found at:\n\n    https://releases.hashicorp.com/terraform    \n\nFind the desired version and input its version number here.\n Example: '0.00.00'\n\n";;
                * )
                    terraDebugTool Change "TERRA SET" "Value '${terraSaved}' approved.\n"
                    break;;
            esac
        done
    fi
    terraSet "${terraSaved}" "${3}"
    terraDebugTool Pass "TERRA SET" "Complete.\n"
elif [[ $1 == "-a" ]] || [[ $1 == "--add" ]]; then
    terraDebugTool Pass "TERRA ACTION" "${1} used.\n"
    if [[ -z $terraSaved ]]; then
        terraDebugTool Fail Version "not found.\n"
        terraLogo
        while true; do
            read -p "Please enter the Terraform version: " terraSaved
            case $terraSaved in
                '' ) 
                    terraDebugTool Unchange "TERRA ADD" "Value entered is '${terraSaved}'.\n"
                    echo "A value must exist!";;
                help )
                    terraDebugTool Unchange "TERRA ADD" "Display '${terraSaved}' for terraAdd.\n"
                    printf "\nTo take advantage of this application it helps to know what\nversions are available. A list of versions can be found at:\n\n    https://releases.hashicorp.com/terraform    \n\nFind the desired version and input its version number here.\n Example: '0.00.00'\n\n";;
                * )
                    terraDebugTool Change "TERRA ADD" "Value '${terraSaved}' approved.\n"
                    break;;
            esac
        done
    fi
    terraAdd "$terraSaved" "$3"
    terraDebugTool Pass "TERRA ADD" "Complete.\n"
elif [[ $1 == "-d" ]] || [[ $1 == "--del" ]]; then
    terraDebugTool Pass "TERRA ACTION" "${1} used.\n"
    if [[ -z $terraSaved ]]; then
        terraDebugTool Fail Version "not found.\n"
        terraLogo
        while true; do
            read -p "Please enter the Terraform version: " terraSaved
            case $terraSaved in
                '' ) 
                    terraDebugTool Unchange "TERRA DELETE" "Value entered is '${terraSaved}'.\n"
                    echo "A value must exist!";;
                help )
                    terraDebugTool Unchange "TERRA DELETE" "Display '${terraSaved}' for terraDelete.\n"
                    printf "\nPlease see bellow a list of versions available to delete.\n\n"
                    terraList;;
                * )
                    terraDebugTool Change "TERRA DELETE" "Value '${terraSaved}' approved.\n"
                    break;;
            esac
        done
    fi
    terraDelete "$terraSaved"
    terraDebugTool Pass "TERRA DELETE" "Complete.\n"
elif [[ $1 == "-l" ]] || [[ $1 == "--list" ]]; then
    terraDebugTool Pass "TERRA ACTION" "${1} used.\n"
    terraLogo
    terraList
    terraDebugTool Pass "TERRA LIST" "Complete.\n"
elif [[ $1 == "-h" ]] || [[ $1 == "--help" ]]; then
    terraDebugTool Pass "TERRA ACTION" "${1} used.\n"
    terraLogo
    terraHelp
    terraDebugTool Pass "TERRA HELP" "Complete.\n"
elif [[ $1 == "-v" ]] || [[ $1 == "--version" ]]; then
    terraDebugTool Pass "TERRA ACTION" "${1} used.\n"
    terraLogo
    terraVersion
    terraDebugTool Pass "TERRA VERSION" "Complete.\n"
else
    terraDebugTool Fail "TERRA ACTION" "not found.\n"
    terraLogo
    printf "Welcome to terra, this tool has been developed to enable users a\nclean way to navigate Terraform versions within a Linux system.\n\nIf you wish to take advantage of this tool, please use the\n\033[0;32m[-h]\033[0m or --help extension to display all commands available.\n\n"
    terraDebugTool Pass "TERRA WELCOME" "Complete.\n"
fi
terraDebugTool Change "END TERRA" "Good Bye\n"