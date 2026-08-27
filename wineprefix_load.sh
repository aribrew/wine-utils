#!/bin/bash

# This script is meant for sourcing only, thus the SCRIPT_HOME
# need to store $1, not $0
SCRIPT_HOME=$(realpath $(dirname $1))

source "$SCRIPT_HOME/bash_helpers"
source "$SCRIPT_HOME/wine_helpers"


load_prefix()
{
    if ! [[ "$1" =~ "/" ]];
    then
        local PREFIX="$WINE_PREFIXES/$1"
    else
        local PREFIX="$1"
    fi

    echo -e "Trying loading '$PREFIX' WINE prefix..."

    is_wine_prefix "$PREFIX"

    if [[ "$?" == "0" ]];
    then
        export WINEPREFIX="$PREFIX"

        if [[ -f "$PREFIX/.arch" ]];
        then
            export WINEARCH=$(cat "$PREFIX/.arch")
        else
            if [[ -d "$PREFIX/drive_c/Program Files (x86)" ]];
            then
                export WINEARCH="win64"
            else
                export WINEARCH="win32"
            fi
        fi

        export WIN_C="$WINEPREFIX/drive_c"
        export WIN_D="$WINEPREFIX/drive_d"

        echo -e "WINE prefix '$WINEPREFIX' ($WINEARCH) activated.\n"

        if [[ -v WINELOADER ]];
        then
            if [[ "$WINE_ARCH" == "win32" ]] &&
               [[ "$WINEARCH" == "win64" ]];
            then
                echo -e "Loading the default WINE for prefix architecture..."

                if [[ -d "$HOME/.wine" ]];
                then
                    wine_load.sh "$HOME/.wine64"
                else
                    abort "Failed."
                fi

            elif [[ "$WINE_ARCH" == "win64" ]] &&
                 [[ "$WINEARCH" == "win32" ]];
            then
                echo -e "Loading the default WINE for prefix architecture..."

                if [[ -d "$HOME/.wine" ]];
                then
                    wine_load.sh "$HOME/.wine"
                else
                    abort "Failed."
                fi
            fi
        else
            echo -e "No WINE environment detected."

            if [[ -v WINE_AUTOLOAD ]];
            then
                if [[ -v WINE_PATH ]];
                then
                    echo -e "A custom WINE_PATH was provided and will be loaded."

                    wine_load.sh "$WINE_PATH"
                else
                    echo -e "Now the default WINE installation will be loaded."

                    wine_load.sh
                fi
            fi
        fi
    fi
}


usage()
{
    echo -e "Usage: \n"
    echo -e "wineprefix_load.sh [WINE prefix name/path]"
    echo -e ": Load the given WINE prefix."
    echo -e "  If none is provided, loads the default one."
    echo -e ""
    echo -e "  If WINE_AUTOLOAD=1 is provided, the default WINE installation"
    echo -e "  will also be loaded."
}


if [[ "$1" == "" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    abort
fi


if [[ "$?" == "0" ]];
then
    load_prefix "$1"
else
    abort "Not a valid WINE prefix."
fi
