#!/bin/bash

source bash_helpers.sh

if ! [[ -v BASH_HELPERS_LOADED ]];
then
    echo -e "BASH Helpers not found in PATH. Install them first.\n"
    exit 1
fi


usage()
{
    echo -e "Usage: win_start.sh <executable> [args]\n"
}


if [[ "$1" == "" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    abort
fi


EXEC=$1

if ! [[ "$EXEC" == "" ]] && [[ -f "$EXEC" ]];
then
    if ! [[ -v WINE_ENV ]];
    then
        abort "Cannot find WINE_ENV var. WINE environment not loaded."
    fi

    ARGS=${@:2}

    EXEC_TYPE=$(exec_type "$EXEC")

    if [[ "$EXEC_TYPE" == "windows-i386" ]];
    then
        if ! [[ -f "$WINE_ENV/.default_wine32" ]];
        then
            abort "Install a WINE version for 32 bits apps."
        fi

        if ! [[ -d "$HOME/.wine/dosdevices" ]];
        then
            abort "Install a WINE prefix for win32 apps."
        fi

        . wine_load.sh $(cat "$WINE_ENV/.default_wine32")
        . "$HOME/.wine/activate"
        
    elif [[ "$EXEC_TYPE" == "windows-amd64" ]];
    then
        if ! [[ -f "$WINE_ENV/.default_wine64" ]];
        then
            abort "Install a WINE version for 64 bits apps."
        fi

        if ! [[ -d "$HOME/.wine64/dosdevices" ]];
        then
            abort "Install a WINE prefix for win64 apps."
        fi

        . wine_load.sh $(cat "$WINE_ENV/.default_wine64")
        . "$HOME/.wine64/activate"
    else
        abort "The specified executable isn't a Windows 32/64 bit one."
    fi

    if [[ -v WINELOADER ]] && [[ -v WINEPREFIX ]];
    then
        echo -en "Launching '$EXEC'"

        if ! [[ "$ARGS" == "" ]];
        then
            echo -en " with args '$ARGS'"
        fi
        
        echo -e " ..."
        
        "$WINELOADER" "$ARGS"
    fi
fi
