#!/bin/bash


if ! [[ -v BASH_HELPERS_LOADED ]];
then
    # Tell us where is, or should be, the bash_helpers.sh script
    BASH_HELPERS=$("$SCRIPT_HOME/bash_helpers.sh" --path)

    if [[ -f "$BASH_HELPERS" ]];
    then
        "$SCRIPT_HOME/bash_helpers.sh" --install
    fi
    
    source "$SCRIPT_HOME/bash_helpers.sh"
fi


echo -e "Installing some required packages..."


sudo apt install -y file 

if ! [[ "$?" == "0" ]];
then
    abort "Some packages failed to install."
fi

