#!/bin/bash

mapfile -t dirList < <(ls /usr/local/terraform/ -1)

if [[ $1 == "--debug" ]]; then
    terraDebug="true"
elif [[ $2 == "--debug" ]]; then
    terraDebug="true"
    terraAction=${1}
elif [[ $3 == "--debug" ]]; then
    terraDebug="true"
    terraAction=${1}
    terraSaved=${2}
elif [[ $4 == "--debug" ]]; then
    terraDebug="true"
    terraAction=${1}
    terraSaved=${2}
    terraInstruction=${3}
else
    terraAction=${1}
    terraSaved=${2}
    terraInstruction=${3}
fi

# *** Debug *********************************

terraFlag() {
    if [[ ${1} == "ERROR" ]]; then
        printf "\e[1;31m%s" "${2}" #Red
    elif [[ ${1} == "Pass" ]]; then
        printf "\033[0;32m%s" "${2}" # Green
    elif [[ ${1} == "Fail" ]]; then
        printf "\e[0;31m%s" "${2}" # Red
    elif [[ ${1} == "Change" ]]; then
        printf "\033[0;33m%s" "${2}" # Yellow
    elif [[ ${1} == "Unchange" ]]; then
        printf "\e[0;95m%s" "${2}" # Purple
    elif [[ ${1} == "Active" ]]; then
        printf "\e[1;94m%s" "${2}" # High Intent Blue
    elif [[ ${1} == "System" ]]; then
        printf "\e[1;36m%s" "${2}" # B Cyan 
    elif [[ ${1} == "Help" ]]; then
        printf "\e[1;32m%s" "${2}" # Green
    else
        printf "\033[0m%s" "${2}" # Standard
    fi
}

terraDebugTool() {
    if [[ $terraDebug == "true" ]] || [[ $1 == "ERROR" ]]; then
        terraFlag "${1}" "[${2}]"
        terraFlag None " ${3}"
        printf "\n\n"
    elif [[  $1 == "Help"  ]]; then
        terraFlag "${1}" "[${2}]"
        terraFlag None " ${3}"
    fi
    if [[ ${4} == "leave" ]]; then
        terraLeave;
    fi
}

# *** Debug ~ END *********************************

terraDebugTool System "START TERRA" "Welcome, Debug and Flags have loaded in."

# *** Installs *********************************

installUnzip() {
    terraDebugTool Change "START TASK" "Installing Unzip."
    sudo apt install unzip -y || terraDebugTool ERROR "InstallFailed" "Unzip install was unsuccessful." leave
    echo
    terraDebugTool Pass "END TASK" "Install Unzip successful!."
}

installCurl() {
    terraDebugTool Change "START TASK" "Installing Curl."
    sudo apt install curl -y || terraDebugTool ERROR "InstallFailed" "Curl install was unsuccessful." leave
    echo
    terraDebugTool Pass "END TASK" "Install Curl successful!."
}

# *** Installs ~ END *********************************

terraDebugTool System "START TERRA" "Installs list, passed."

# *** General *********************************

terraLogo() {
    if [[ ${terraLogoDisp} != "false" ]]; then
        terraDebugTool Change "LOGO TASK" "Change 'terraLogoDisp' Variable to true. This will prevent the Logo from being produced again."
        terraLogoDisp="false"
        cat <<EOF

    __________________________________________    _____ 
    \__    ___/\_   _____/\______   \______   \  /  _  \   
      |    |    |    __)_  |       _/|       _/ /  /_\  \  
      |    |    |        \ |    |   \|    |   \/    |    \ 
      |____|   /_______  / |____|_  /|____|_  /\____|__  / 
                       \/         \/        \/         \/  

EOF
    else
        terraDebugTool Unchange "LOGO TASK" "'terraLogoDisp' Variable is false, Skip logo display."
    fi
}

terraHelp() {
    printf "terra "
    terraDebugTool Help "Action"
    terraFlag Change "[Version] "
    terraFlag Unchange "[Instruction]"
    printf "\n\n"

    terraDebugTool Help "-s" "or "
    terraDebugTool Help "--set" "can be used to make the desired version active. "
    terraFlag Change "[Version]"
    terraFlag None " can be included. "
    terraFlag Unchange "[-v]"
    terraFlag None " or "
    terraFlag Unchange "[--version]"
    terraFlag None " will print the version."
    printf "\n\n"

    terraDebugTool Help "-a" "or "
    terraDebugTool Help "--add" "can be used to install the desired version. "
    terraFlag Change "[Version]"
    terraFlag None " can be included. " 
    terraFlag Unchange "[-y]"
    terraFlag None " will force overwite if already available."
    printf "\n\n"
    
    terraDebugTool Help "-d" "or "
    terraDebugTool Help "--del" "can be used to fully remove the desired version and folder. "
    terraFlag Change "[Version]"
    terraFlag None " can be included."
    printf "\n\n"
    
    terraDebugTool Help "-l" "or "
    terraDebugTool Help "--list" "is used to display all versions currently available."
    printf "\n\n"
    
    terraDebugTool Help "-v" "or "
    terraDebugTool Help  "--version" "is used to display all versions currently available."
    printf "\n\n"
}

terraLeave() {
    exit 1
}

# *** General ~ END *********************************

terraDebugTool System "START TERRA" "General list, passed."

# *** Create *********************************

terraAdd() {
    terraDebugTool Change "START TASK" "Add Terraform ${1}."

    terraDownload "${1}" "linux_amd64.zip"
    terraDownload "${1}" "SHA256SUMS"

    sha256sum -c --ignore-missing --status "terraform_${1}_SHA256SUMS" || terraDebugTool ERROR "CHECK TASK" "Sha256sum did not match!" leave
    terraDebugTool Pass "CHECK TASK" "Sha256sum pessed."

    if [[ ! -d /usr/local/terraform/${1} ]]; then
        terraDebugTool Change "CREATE TASK" "/usr/local/terraform/${1} directory.\n"
        sudo mkdir -p "/usr/local/terraform/${1}"
    else
        terraDebugTool Unchange "CREATE TASK" "Directory at /usr/local/terraform/${1} found."
        while true; do
                if [[ ${2} == "-y" ]]; then
                    yn="y"
                    terraDebugTool Pass "CREATE TASK" "Prompt to overwrite skipped."
                else
                    read -r -p "Do you wish to overwrite this directory (Y/N)? " yn # Optional Pull of git changes
                fi
                case $yn in
                    [Yy]* ) 
                        terraDebugTool Change "CREATE TASK" "Set to overwite /usr/local/terraform/${1} directory."
                        break;;
                    [Nn]* )
                        echo
                        sudo rm -rf "terraform_${1}_linux_amd64.zip" || terraDebugTool ERROR "REMOVE TASK" "Failed to remove 'terraform_${1}_linux_amd64.zip'."
                        sudo rm -rf "terraform_${1}_SHA256SUMS" || terraDebugTool ERROR "REMOVE TASK" "Failed to remove 'terraform_${1}__SHA256SUMS'."
                        terraDebugTool ERROR STOPPED "Overwrite prevented by user." leave;;
                    * ) echo "Please answer with 'y' or 'n'.";;
                esac
            done
    fi

    if [[ "$(unzip -v 2>/dev/null)" = "" ]]; then
        terraDebugTool Fail "REQUIRED" "Unzip not found, forcing install to release .zip packages."
        installUnzip
    else
        terraDebugTool Pass "REQUIRED" "Unzip installed.\n"
    fi

    terraDebugTool Change "UNZIP TASK" "Extract files from terraform_${1}_linux_amd64.zip.\n"
    terraFlag Change
    sudo unzip -o "terraform_${1}_linux_amd64.zip" -d "/usr/local/terraform/${1}/" 1> /dev/null || terraDebugTool FERRORail "UNZIP TASK" "Failed to extract files." leave
    terraDebugTool Pass "UNZIP TASK" "Files from terraform_${1}_linux_amd64.zip extraction successful."

    terraDebugTool Change "REMOVE TASK" "Remove unwanted files."
    terraFlag Change
    sudo rm -rf "terraform_${1}_linux_amd64.zip" || terraDebugTool ERROR "REMOVE TASK" "Failed to remove 'terraform_${1}_linux_amd64.zip'."
    sudo rm -rf "terraform_${1}_SHA256SUMS" || terraDebugTool ERROR "REMOVE TASK" "Failed to remove 'terraform_${1}__SHA256SUMS'."
    terraDebugTool Pass "REMOVE TASK" "Remove files successful."

    terraDebugTool Pass "END TASK" "Add Terraform ${1} successful."
    terraInstall "${1}"
}

terraDownload() {
    terraDebugTool Change "START TASK" "Download Terraform ${2}."

    if [[ "$(curl --version 2>/dev/null)" = "" ]]; then
        terraDebugTool Fail "REQUIRED" "Curl not found, forcing install to download files."
        installCurl
    else
        terraDebugTool Pass "REQUIRED" "Curl installed."
    fi

    terraFlag Fail
    curl -sSO --fail "https://releases.hashicorp.com/terraform/${1}/terraform_${1}_${2}" || terraDebugTool ERROR "FAILED TASK" "Unable to download ${2} File." leave
    
    terraDebugTool Pass "END TASK" "Downloaded Terraform ${2} successful."
}

terraInstall() {
    terraDebugTool Change "START TASK" "Install Terraform ${1}."
    
    terraPriority "${1}"

    terraDebugTool Change "INSTALL TASK" "Applying Terraform ${1} to activatable stack."
    terraFlag Change
    sudo update-alternatives --install /usr/local/bin/terraform terraform /usr/local/terraform/"${1}"/terraform "${PRIORITY}" || terraDebugTool ERROR "FAILED TASK" "Unable to install Terraform ${1}." leave
    
    terraDebugTool Pass "END TASK" "Install Terraform ${1} successful."
}

terraPriority() {
    terraDebugTool Change "START TASK" "Resolving ${1} into priority value."

    terraDebugTool Change "PRIORITY TASK" "Isolate version digits into array to later be recompiled."
    IFS='.'
    for i in $1; do
        VAR+=( "$i" )
    done
    IFS=' '
    terraDebugTool Pass "PRIORITY TASK" "Digits isolated into Release[${VAR[0]}] Bata[${VAR[1]}] Alpha[${VAR[2]}] versions."

    if [[ ${VAR[2]} -lt 10 ]]; then
        terraDebugTool Change "PRIORITY TASK" "Alpha version is not is not in double digit values."
        VAR[2]="0${VAR[2]}"
    fi
    
    if [[ ${VAR[1]} -lt 10 ]]; then
        terraDebugTool Change "PRIORITY TASK" "Beta version is not is not in double digit values."
        VAR[1]="0${VAR[1]}"
    fi

    if [[ ${VAR[0]} -gt 0 ]]; then
        terraDebugTool Change "PRIORITY TASK" "Set priority with release version."
        PRIORITY="${VAR[0]}${VAR[1]}${VAR[2]}"
    else
        terraDebugTool Change "PRIORITY TASK" "Set priority with no release version."
        PRIORITY="${VAR[1]}${VAR[2]}"
    fi
    terraDebugTool Pass "PRIORITY TASK" "Priority resolved to ${PRIORITY}."

    terraDebugTool Change "END TASK" "Priority resolve successful."
}

# *** Create ~ END *********************************

terraDebugTool System "START TERRA" "Create list, passed."

# *** Read *********************************

terraList() {
    terraDebugTool Change "START TASK" "Gather a list of available versions."

    terraDebugTool Unchange "LIST TASK" "Get number of files in directory."
    dirNum=${#dirList[@]}
    terraDebugTool Change "LIST TASK" "Reduce value."
    dirNum=$(((dirNum - 1)))

    terraDebugTool Change "LIST TASK" "Print all versions and highlight active."
    for (( c=0; c<=dirNum; c++ )); do
            if [[  $terraVerFound == "true"  ]]; then
                printf "%s" "${dirList[${c}]}"
            elif terraform --version | grep "${dirList[${c}]}" &>/dev/null; then
                terraFlag Active "${dirList[${c}]}"
                terraFlag None
                terraVerFound="true"
            else
                printf "%s" "${dirList[${c}]}"
            fi
            if [[ $c != "$dirNum" ]]; then
                printf "\n"
            else
                printf "\n\n"
            fi
    done

    terraDebugTool Pass "END TASK" "Terraform list successful."
}

terraVersion() {
    terraDebugTool Change "START TASK" "Dispaly terraform --version output."
    terraFlag "${setFlag}"
    terraform --version
    terraDebugTool Pass "END TASK" "Dispaly version output successful."
}

# *** Read ~ END *********************************

terraDebugTool System "START TERRA" "Read list, passed."

# *** update *********************************

terraSet() {
    terraDebugTool Change "START TASK" "Set Terraform ${1}."
    if [[ ${1} == "auto" ]]; then
        terraDebugTool Change "SET TASK" "Set Terraform to ${1}."
        terraFlag Change
        sudo update-alternatives --auto terraform
    else
        if [[ ! -d /usr/local/terraform/${1} ]]; then
            terraDebugTool Fail "SET TASK" "Version is not installed."
            terraAdd "${1}"
            setFlag="Change"
        elif ! update-alternatives --list terraform | grep "${terraSaved}" &> /dev/null; then
            terraDebugTool Fail "SET TASK" "Version directory found but not installed."
            terraInstall "${1}"
            setFlag="Change"
        elif terraform --version -json | grep "${terraSaved}" &> /dev/null; then
            terraDebugTool Active "SET TASK" "Version is already active."
            setFlag="Unchange"
        else
            setFlag="Pass"
        fi

        if [[  $setFlag !=  "Unchange" ]]; then
            terraDebugTool "${setFlag}" "SET TASK" "Set to Terraform ${1}."
            sudo update-alternatives --set terraform "/usr/local/terraform/${1}/terraform" &> /dev/null || terraDebugTool ERROR "SET TASK" "To ${1} was not Successful." leave
        fi
    fi
    if [[  $2 == -v  ]] || [[  $2 == --version  ]]; then
        terraDebugTool Unchange "SET TASK" "Version request found."
        terraVersion
    fi
    terraDebugTool Pass "END TASK" "Set Terraform ${1} successful."
}

# *** Update ~ END *********************************

terraDebugTool System "START TERRA" "Update list, passed."

# *** Delete *********************************

terraDelete() {
    terraDebugTool Pass "START TASK" "Delete Terraform ${1}."
    
    if update-alternatives --list terraform | grep "${terraSaved}" &>/dev/null; then
        terraDebugTool Fail "DELETE TASK" "Terraform ${1} is active in version stack."
        terraUninstall "${1}"
    fi

    terraDebugTool Change "DELETE TASK" "Delete /usr/local/terraform/${1} directory and its contents."
    sudo rm -rf "/usr/local/terraform/${1}" || terraDebugTool ERROR "DELETE TASK" "Unable to delete /usr/local/terraform/${1} for system." leave

    terraDebugTool Pass "END TASK" "Terraform ${1} delete successful."
}

terraUninstall() {
    terraDebugTool Change "START TASK" "uninstall Terraform ${1}."
    
    terraDebugTool Change "UNINSTALL TASK" "Uninstall Terraform ${1} from version stack."
    if terraform --version -json | grep "${terraSaved}" &>/dev/null; then
        terraDebugTool Fail "UNINSTALL TASK" "Terraform ${1} is active."
        terraSet "auto"
    fi
    terraFlag Change
    sudo update-alternatives --remove terraform "/usr/local/terraform/${1}/terraform" || terraDebugTool ERROR "UNINSTALL TASK" "Terraform ${1} version failed to uninstall." leave

    terraDebugTool Pass "END TASK" "Terraform ${1} uninstall successful!."
}

# *** Delete ~ END *********************************

terraDebugTool System "START TERRA" "Delete list, passed."

if [[ ! -d /usr/local/terraform  ]]; then
    terraDebugTool Help "SETUP TERRA" "'/usr/local/terraform' directory created to store Terraform versions."
    printf "\n\n"
    sudo mkdir /usr/local/terraform
    if [[ -z $terraAction ]]; then 
        terraLogo
        terraDebugTool Help "Welcome" "Terra is here to help you navigate Terraform Versions, bellow are a set of tools available."
        printf "\n\n"
        terraHelp
        terraDebugTool Help "-h" "or "
        terraDebugTool Help "--help" "is used to display this list again."
        printf "\n"
        terraLeave
    fi
fi

if [[ $terraAction == "-s" ]] || [[ $terraAction == "--set" ]]; then
    terraDebugTool Pass "TERRA ACTION" "${terraAction} used."
    if [[ -z $terraSaved ]]; then
        terraDebugTool Unchange "TERRA SET" "Version value not present."
        terraLogo
        while true; do
            read -r -p "Please enter the Terraform version: " terraSaved terraInstruction
            case $terraSaved in
                '' ) 
                    terraDebugTool Unchange "TERRA SET" "Value entered is '${terraSaved}'."
                    printf "\nA value must exist! Use \e[1;32mhelp\033[0m if you require assistance.\n\n";;
                help )
                    terraDebugTool Unchange "TERRA SET" "Display '${terraSaved}' for terraSet."
                    printf "\nAvailable versions to set:\n\n"
                    terraList
                    printf "To Set a version it must first be installed. A list of\nversions that can be installed are found at:\n\n    \e[1;32mhttps://releases.hashicorp.com/terraform\033[0m    \n\nFind the desired version and input its version number here.\n\nExample: '\033[0;33m0.00.00\033[0m'\n\nUse \e[0;95m-v\033[0m or \e[0;95m--version\033[0m to display the version readout once set.\n\n";;
                exit ) 
                    echo
                    terraDebugTool ERROR STOPPED "Aborted by user." leave;;
                * )
                    terraDebugTool Change "TERRA SET" "Value '${terraSaved}' approved."
                    break;;
            esac
        done
    fi
    terraSet "${terraSaved}" "${terraInstruction}"
    terraDebugTool Pass "TERRA SET" "Complete."
elif [[ $terraAction == "-a" ]] || [[ $terraAction == "--add" ]]; then
    terraDebugTool Pass "TERRA ACTION" "${terraAction} used."
    if [[ -z $terraSaved ]]; then
        terraDebugTool Fail Version "not found."
        terraLogo
        while true; do
            read -r -p "Please enter the Terraform version: " terraSaved terraInstruction
            case $terraSaved in
                '' ) 
                    terraDebugTool Unchange "TERRA ADD" "Value entered is '${terraSaved}'."
                    printf "\nA value must exist! Use \e[1;32mhelp\033[0m if you require assistance.\n\n";;
                help )
                    terraDebugTool Unchange "TERRA ADD" "Display '${terraSaved}' for terraAdd."
                    printf "\nTo take advantage of this application it helps to know what\nversions are available. A list of versions can be found at:\n\n    \e[1;32mhttps://releases.hashicorp.com/terraform\033[0m    \n\nFind the desired version and input its version number here.\n\nExample: '\033[0;33m0.00.00\033[0m'\n\nUse \e[0;95m-y\033[0m to force overwire if applicable.\n\n";; # Made By Sean David McCann
                exit ) 
                    echo
                    terraDebugTool ERROR STOPPED "Aborted by user." leave;;
                * )
                    terraDebugTool Change "TERRA ADD" "Value '${terraSaved}' approved."
                    break;;
            esac
        done
    fi
    terraAdd "$terraSaved" "$terraInstruction"
    terraDebugTool Pass "TERRA ADD" "Complete."
elif [[ $terraAction == "-d" ]] || [[ $terraAction == "--del" ]]; then
    terraDebugTool Pass "TERRA ACTION" "${terraAction} used."
    if [[ -z $terraSaved ]] || [[ $terraSaved == "--debug" ]]; then
        terraDebugTool Fail Version "not found."
        terraLogo
        while true; do
            read -r -p "Please enter the Terraform version: " terraSaved
            case $terraSaved in
                '' ) 
                    terraDebugTool Unchange "TERRA DELETE" "Value entered is '${terraSaved}'."
                    printf "A value must exist! Use \e[1;32mhelp\033[0m if you require assistance.\n";;
                help )
                    terraDebugTool Unchange "TERRA DELETE" "Display '${terraSaved}' for terraDelete."
                    printf "\nPlease see bellow a list of versions available to delete.\n\n"
                    terraList;;
                exit ) 
                    echo
                    terraDebugTool ERROR STOPPED "Aborted by user." leave;;
                * )
                    terraDebugTool Change "TERRA DELETE" "Value '${terraSaved}' approved."
                    break;;
            esac
        done
    fi
    terraDelete "$terraSaved"
    terraDebugTool Pass "TERRA DELETE" "Complete.\n"
elif [[ $terraAction == "-l" ]] || [[ $terraAction == "--list" ]]; then
    terraDebugTool Pass "TERRA ACTION" "${terraAction} used."
    terraLogo
    terraList
    terraDebugTool Pass "TERRA LIST" "Complete."
elif [[ $terraAction == "-h" ]] || [[ $terraAction == "--help" ]]; then
    terraDebugTool Pass "TERRA ACTION" "${terraAction} used."
    terraLogo
    terraHelp
    terraDebugTool Pass "TERRA HELP" "Complete."
elif [[ $terraAction == "-v" ]] || [[ $terraAction == "--version" ]]; then
    terraDebugTool Pass "TERRA ACTION" "${terraAction} used."
    terraLogo
    terraVersion
    terraDebugTool Pass "TERRA VERSION" "Complete."
elif [[ $terraAction == "--logo-toggle" ]]; then
    terraDebugTool Pass "TERRA ACTION" "${terraAction} used."
    if [[ $terraLogoDisp != "false" ]]; then
        echo
        echo "Use 'export terraLogoDisp=\"false\"' to disable Logo printout."
        echo
    else
        echo
        echo "Use 'export terraLogoDisp=\"true\"' to enable Logo printout."
        echo
    fi
    terraDebugTool Pass "TERRA LOGO-DISPLAY" "Complete."
else
    terraDebugTool Fail "TERRA ACTION" "not found."
    terraLogo
    printf "Welcome to terra, this tool has been developed to enable users a\nclean way to navigate Terraform versions within a Linux system.\n\nIf you wish to take advantage of this tool, please use "
    terraDebugTool Help "-h" "or "
    printf "\n"
    terraDebugTool Help "--Help"
    printf "for a list of actionable commands. Incorporate them with \nterra to perform actions in a single action. \n"
    terraDebugTool Pass "TERRA WELCOME" "Complete."
fi
terraDebugTool System "END TERRA" "Good Bye"
