#!/bin/bash

BASH_HELPERS="/opt/bin/bash_helpers"
SCRIPTS=$(realpath $(dirname $0))


if ! [ -f "$BASH_HELPERS" ] &&
     [ -f "$SCRIPTS/bash_helpers" ];
then
    "$SCRIPTS/helpers/bash_helpers" install
fi


if ! [ -f "$BASH_HELPERS" ];
then
    echo "Cannot find /opt/bin/bash_helpers."
    echo ""

    exit 1
    
else
    source "$BASH_HELPERS"
fi


WINETRICKS_URL="https://raw.githubusercontent.com/Winetricks/winetricks"
WINETRICKS_URL+="/master/src/winetricks"


if ! [ -f "/usr/bin/cabextract" ] || ! [ -f "/usr/bin/zstd" ] ||
   ! [ -f "/usr/bin/zenity" ];
then
    echo "Installing Winetricks dependencies ..."
    echo "--------------------------------------"
    
    sudo apt install -y cabextract zstd zenity

    if ! [ "$?" == "0" ];
    then
        abort "Failed."
    fi
fi


echo ""
echo "Downloading Winetricks ..."
echo "--------------------------"


wget -N $WINETRICKS_URL

if ! [ "$?" == "0" ];
then
    abort "Failed. Maybe the Winetricks URL is down..."
fi

