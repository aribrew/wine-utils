#!/bin/bash

BASH_HELPERS="/opt/bin/bash_helpers"

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


if [[ -f "$HOME/.local/bin/winenv/.wine_env" ]]; 
then
    INSTALL_PATH="$HOME/.local/bin/winenv"
else
    INSTALL_PATH="$HOME/.local/bin"    
fi


if [[ -d "$INSTALL_PATH" ]];
then
    mkdir -p "$INSTALL_PATH"
    
    mv winetricks "$INSTALL_PATH/winetricks"
    chmod 770 "$INSTALL_PATH/winetricks"
fi

