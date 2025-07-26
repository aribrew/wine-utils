#!/bin/bash

#############################################################################
# Downloads WINE GPG key and install it along with the WINE repo source.
# Also enables the 'contrib' repository, needed to download Winetricks
#############################################################################


BASH_HELPERS="/opt/bin/bash_helpers"
SCRIPTS=$(realpath $(dirname $0))


if ! [[ -f "$BASH_HELPERS" ]] &&
     [[ -f "$SCRIPTS/helpers/bash_helpers" ]]; 
then
    "$SCRIPTS/bash_helpers" install
fi


if ! [[ -f "$BASH_HELPERS" ]]; 
then
    echo "Cannot find '$BASH_HELPERS'."
    echo ""

    exit 1
    
else
    source "$BASH_HELPERS"
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
    echo "Enabling i386 repository if not available yet ..."

    sudo dpkg --add-architecture i386

    SOURCES_LIST="/etc/apt/sources.list"

    echo ""
    echo "Checking if 'contrib' repository is already enabled ..."

    if [[ -f "$SOURCES_LIST" ]]; 
    then
        cat "$SOURCES_LIST" | grep -q " contrib"

        if [[ "$?" == "0" ]]; 
        then
            echo "All OK. Nothing to do here."
            echo ""

        else
            if [[ "$(which apt-add-repository)" == "" ]]; 
            then
                echo ""
                echo "Installing software-properties-common first ..."
                echo "----------------------------------------------"

                sudo apt update
                sudo apt install software-properties-common -y

                if ! [[ "$?" == "0" ]]; 
                then
                    abort "Failed. Maybe there is something wrong with APT."
                fi
            fi

            echo ""
            echo "Enabling 'contrib' repository ..."
            echo "---------------------------------"

            sudo apt-add-repository contrib -y

            if ! [[ "$?" == "0" ]]; 
            then
                abort "Failed. No 'contrib' repo in this distro?"
            fi
        fi
    fi


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

