#!/bin/bash

#############################################################################
# Downloads WINE GPG key and install it along with the WINE repo source.
#############################################################################


source bash_helpers.sh

if ! [[ -v BASH_HELPERS_LOADED ]];
then
    echo -e "BASH helpers not found in PATH. Install it first.\n"
    exit 1
fi




OS_NAME=$(os_name)
OS_VERSION=$(os_version)


if [[ "$OS_NAME" == "arch" ]]; 
then
    echo "If want to use Wine in ArchLinux (or Manjaro), it is recommended to"
    echo "use Lutris instead, or a podman container with Debian testing."
    echo ""

    abort "ArchLinux does not support Wine (i386) (32 bit)."
fi


APT_SOURCES_DIR="/etc/apt/sources.list.d"
APT_KEYRINGS_DIR="/etc/apt/keyrings"

WINE_APT_URL="https://dl.winehq.org/wine-builds/${OS_NAME}"
WINE_APT_URL+="/dists/${OS_VERSION}"
WINE_APT_URL+="/winehq-${OS_VERSION}.sources"

WINE_GPG_URL="https://dl.winehq.org/wine-builds/winehq.key"


if ! [[ -d "$APT_KEYRINGS_DIR" ]]; 
then
    sudo mkdir -p "$APT_KEYRINGS_DIR"
fi


if ! [[ -f "$APT_SOURCES_DIR/winehq-${OS_VERSION}.sources" ]] ||
   ! [[ -f "$APT_KEYRINGS_DIR/winehq-archive.key" ]]; 
then
    echo ""
    echo "-e Enabling i386 repository if not available yet ...\n"

    sudo dpkg --add-architecture i386

    sudo apt update

    if [[ "$(which wget)" == "" ]];
    then
        echo -e "\nInstalling wget ..."
        echo -e "---------------------"
        
        sudo apt install -y wget

        if ! [[ "$?" == "0" ]];
        then
            abort "Failed!"
        fi
    fi

    SOURCES_LIST="/etc/apt/sources.list"
    

    echo ""
    echo "Downloading WINE GPG key and sources.list for APT..."
    echo "----------------------------------------------------"
    echo ""

    wget -N $WINE_GPG_URL

    if ! [[ "$?" == "0" ]]; 
    then
        abort "Failed downloading GPG key."
    fi


    wget -N $WINE_APT_URL

    if ! [[ "$?" == "0" ]]; 
    then
        abort "Failed downloading APT sources list."
    fi


    sudo mv winehq.key "$APT_KEYRINGS_DIR/winehq-archive.key"
    sudo mv winehq-${OS_VERSION}.sources "$APT_SOURCES_DIR/"


    echo "Refreshing APT database ..."
    echo ""

    sudo apt update

    if ! [[ "$?" == "0" ]]; 
    then
        abort "Something is wrong :S"
    fi
fi

