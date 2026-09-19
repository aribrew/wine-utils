#!/bin/bash

# This script is meant for sourcing only, thus the SCRIPT_HOME
# need to store ${BASH_SOURCE[0]}, not $0
SCRIPT_HOME=$(realpath $(dirname ${BASH_SOURCE[0]}))

source "$SCRIPT_HOME/wine_helpers"


usage()
{
    echo "Usage: . winenv_load.sh"
    echo ""
    echo "Loads the default WINE environment into the current"
    echo "shell session."
    echo ""
    echo "This is the WINEPREFIX symlinked in"
    echo "\$HOME/.wine and the WINE installation set in"
    echo "\$HOME/.default_wine."
    echo ""
}


if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    abort
fi


if ! [[ -d "$HOME/.wine/drive_c" ]];
then
    abort "No valid WINEPREFIX in \$HOME/.wine was found."
fi


if ! [[ -f "$HOME/.default_wine" ]];
then
    abort "No default WINE installation found in \$HOME/.default_wine."
fi


. wineprefix_load.sh "$HOME/.wine"


if [[ -v WINEPREFIX ]];
then
    DEFAULT_WINE=$(cat "$HOME/.default_wine")

    if ! [[ -d "$DEFAULT_WINE" ]];
    then
        abort "Invalid WINE installation in \$HOME/.default_wine."
    fi

    . wine_load.sh "$DEFAULT_WINE"

    if [[ -v WINELOADER ]];
    then
        echo -e ""
        echo -e "Default WINE environment loaded. Have fun!\n"
    fi
fi
