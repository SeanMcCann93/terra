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
        printf "\033[0;35m%s" "${2}" # Purple
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
    if [[ $terraDebug == "true" ]] || [[ $1 == "Help" ]] || [[ $1 == "ERROR" ]]; then
        terraFlag "${1}" "[${2}]"
        terraFlag None " ${3}"
        printf "\n\n"
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
    sudo apt install unzip -y || terraDebugTool ERROR "InstallFailed" "Unzip was unsuccessful." leave
    echo
    terraDebugTool Pass "END TASK" "Install Unzip successful!."
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
    terraDebugTool Help "Action" "\033[0;33m[Version]\033[0m \033[0;35m[Instruction]\033[0m"
    terraDebugTool Help "-s] \033[0mor\e[1;32m [--set" "can be used to make the desired version active. \033[0;33m[Version]\033[0m can be included. \033[0;35m[-v]\033[0m or \033[0;35m[--version]\033[0m will print the vestion."
    terraDebugTool Help "-a] \033[0mor\e[1;32m [--add" "can be used to install the desired version. \033[0;33m[Version]\033[0m can be included. \033[0;35m[-y]\033[0m will force overwite if already available."
    terraDebugTool Help "-d] \033[0mor\e[1;32m [--del" "can be used to fully remove the desired version and folder. \033[0;33m[Version]\033[0m can be included."
    terraDebugTool Help "-l] \033[0mor\e[1;32m [--list" "is used to display all versions currently available."
    terraDebugTool Help "-v] \033[0mor\e[1;32m [--version" "is used to display all versions currently available."
}

terraLeave() {
    echo
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
            if terraform --version -json | grep "${dirList[${c}]}"; then
                terraFlag Active "*${dirList[${c}]}"
                terraFlag None
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
    
    if update-alternatives --list terraform | grep "${terraSaved}"; then
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
    if terraform --version | grep "${terraSaved}"; then
        terraDebugTool Fail "UNINSTALL TASK" "Terraform ${1} is active."
        terraSet "auto"
    fi
    terraFlag Change
    sudo update-alternatives --remove terraform "/usr/local/terraform/${1}/terraform" || terraDebugTool ERROR "UNINSTALL TASK" "Terraform ${1} version failed to uninstall." leave

    terraDebugTool Pass "END TASK" "Terraform ${1} uninstall successful!."
}

# *** Delete ~ END *********************************

terraDebugTool System "START TERRA" "Delete list, passed."

if [[ ! -d /usr/local/terraform ]]; then
    terraDebugTool Help "SETUP TERRA" "'/usr/local/terraform' directory created to store Terraform versions."
    sudo mkdir /usr/local/terraform
    terraDebugTool Help "Welcome" "Terra is here to help you navigate Terraform Versions, Bellow are a set of tools available."
    terraHelp
    terraDebugTool Help "-h] \033[0mor\e[1;32m [--help" "is used to display this list again."
fi

if [[ $terraAction == "-s" ]] || [[ $terraAction == "--set" ]]; then
    terraDebugTool Pass "TERRA ACTION" "${terraAction} used."
    if [[ -z $terraSaved ]]; then
        terraDebugTool Unchange "TERRA SET" "Version value not present."
        terraLogo
        while true; do
            read -r -p "Please enter the Terraform version: " terraSaved
            case $terraSaved in
                '' ) 
                    terraDebugTool Unchange "TERRA SET" "Value entered is '${terraSaved}'."
                    echo "A value must exist!";;
                help )
                    terraDebugTool Unchange "TERRA SET" "Display '${terraSaved}' for terraSet."
                    printf "\nAvailable versions to set:\n\n"
                    terraList
                    printf "To Set a version it must first be installed. A list of\nversions that can be installed are found at:\n\n    https://releases.hashicorp.com/terraform    \n\nFind the desired version and input its version number here.\n Example: '0.00.00'\n\n";;
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
            read -r -p "Please enter the Terraform version: " terraSaved
            case $terraSaved in
                '' ) 
                    terraDebugTool Unchange "TERRA ADD" "Value entered is '${terraSaved}'."
                    echo "A value must exist!";;
                help )
                    terraDebugTool Unchange "TERRA ADD" "Display '${terraSaved}' for terraAdd."
                    printf "\nTo take advantage of this application it helps to know what\nversions are available. A list of versions can be found at:\n\n    https://releases.hashicorp.com/terraform    \n\nFind the desired version and input its version number here.\n Example: '0.00.00'\n\n";;
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
                    echo "A value must exist!";;
                help )
                    terraDebugTool Unchange "TERRA DELETE" "Display '${terraSaved}' for terraDelete."
                    printf "\nPlease see bellow a list of versions available to delete.\n\n"
                    terraList;;
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
    if [[ $terraLogoDisp == "true" ]]; then
        echo
        echo "export terraLogoDisp=\"false\""
        echo
    else
        echo
        echo "export terraLogoDisp=\"true\""
        echo
    fi
    terraDebugTool Pass "TERRA LOGO-DISPLAY" "Complete."
else
    terraDebugTool Fail "TERRA ACTION" "not found."
    terraLogo
    printf "Welcome to terra, this tool has been developed to enable users a\nclean way to navigate Terraform versions within a Linux system.\n\nIf you wish to take advantage of this tool, please use "
    terraDebugTool Help "-h] \033[0mor\e[1;32m \n[--Help" "For a list of actionable commands. Incorporate them with\nterra to perform actions in a single action."
    terraDebugTool Pass "TERRA WELCOME" "Complete."
fi
terraDebugTool System "END TERRA" "Good Bye"