#!/bin/bash

SCRIPT_HOME=$(realpath $(dirname $0))

source "bash_helpers"


is_wine_prefix()
{
    local PREFIX="$1"

    if [[ -d "$PREFIX" ]];
    then
        if [[ -d "$PREFIX/dosdevices" ]];
        then
            return 0
        fi
    fi

    return 1
}


load_prefix()
{
    if ! [[ "$1" =~ "/" ]];
    then
        local PREFIX="$WINE_PREFIXES/$1"
    else
        local PREFIX="$1"
    fi

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
                    load_wine "$HOME/.wine64"
                else
                    abort "Failed."
                fi

            elif [[ "$WINE_ARCH" == "win64" ]] &&
                 [[ "$WINEARCH" == "win32" ]];
            then
                echo -e "Loading the default WINE for prefix architecture..."

                if [[ -d "$HOME/.wine" ]];
                then
                    load_wine "$HOME/.wine"
                else
                    abort "Failed."
                fi
            fi
        else
            echo -e "No WINE environment detected."

            if [[ -v WINE_PATH ]];
            then
                echo -e "A custom WINE_PATH was provided and will be loaded."

                load_wine "$WINE_PATH"
            else
                echo -e "Now the default WINE installation will be loaded."

                load_wine
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
}


if [[ "$1" == "" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    abort
fi



export WINE_PREFIXES="$HOME/.local/share/wineprefixes"

is_wine_prefix "$1"

if [[ "$?" == "0" ]];
then
    load_prefix "$1"
else
    abort "Not a valid WINE prefix."
fi
