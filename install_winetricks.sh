#!/bin/bash

BASH_HELPERS="/opt/bin/bash_helpers.sh"

if ! [[ -f "$BASH_HELPERS" ]]; 
then
    echo "Cannot find '$BASH_HELPERS'."
    echo ""

    exit 1
    
else
    source "$BASH_HELPERS"
fi




WINETRICKS_URL="https://raw.githubusercontent.com/Winetricks/winetricks"
WINETRICKS_URL+="/master/src/winetricks"


if ! [[ -f "/usr/bin/cabextract" ]] || ! [[ -f "/usr/bin/zstd" ]] ||
   ! [[ -f "/usr/bin/zenity" ]]; 
then
    echo "Installing Winetricks dependencies ..."
    echo "--------------------------------------"
    
    sudo apt install -y cabextract zstd zenity

    if ! [[ "$?" == "0" ]]; 
    then
        abort "Failed."
    fi
fi


echo ""
echo "Downloading Winetricks ..."
echo "--------------------------"


wget -N $WINETRICKS_URL

if ! [[ "$?" == "0" ]]; 
then
    abort "Failed. Maybe the Winetricks URL is down..."
fi


if [[ -d "$HOME/.local/bin/winenv" ]];
then
    INSTALL_PATH="$HOME/.local/bin/winenv"
    PERMS="770"
    
elif [[ -d "/opt/winenv" ]];
then
    INSTALL_PATH="/opt/winenv"

    SUDO="sudo"
    PERMS="755"
else
    INSTALL_PATH="/usr/local/bin"

    SUDO="sudo"
    PERMS="755"
fi


if ! [[ -d "$INSTALL_PATH" ]];
then
    mkdir -p "$INSTALL_PATH"
fi

$SUDO mv winetricks "$INSTALL_PATH/winetricks"
$SUDO chmod $PERMS "$INSTALL_PATH/winetricks"
