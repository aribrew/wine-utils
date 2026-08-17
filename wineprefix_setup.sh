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


setup_prefix()
{
    export WINEPREFIX="$1"
    export WINEARCH="$2"

    echo -e "Preparing to setup a $WINEARCH prefix in '$WINEPREFIX'...\n"

    PREFIX_PATH=$(dirname "$WINEPREFIX")

    if ! [[ -d "$PREFIX_PATH" ]];
    then
        mkdir -p "$PREFIX_PATH"
    fi

    source wine_load.sh

    "$WINELOADER" "$WINE_UTILS/wineboot.exe"

    if ! [[ "$?" == "0" ]];
    then
        echo -e "Initialization failed.\n"
        echo -e "May be a permissions problem creating the prefix..."
        echo -e "...or some WINE dependencies may be missing..."
        exit 1
    fi

    echo "$WINEARCH" > "$WINEPREFIX/.arch"

    if [[ "$WINEARCH" == "win32" ]] && ! [[ -d "$HOME/.wine" ]];
    then
        set_default_prefix "$WINEPREFIX"

    elif [[ "$WINEARCH" == "win64" ]] && ! [[ -d "$HOME/.wine64" ]];
    then
        set_default_prefix "$WINEPREFIX"
    fi
}


usage()
{
    echo -e "Usage: \n"
    echo -e "wineprefix_setup.sh <prefix name> [win32|win64]"
    echo -e ": Create a new prefix in ~/.local/share/wineprefixes."
    echo -e "  The default architecture, if none is specified, is win64."
}


if [[ "$1" == "" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    abort
fi



export WINE_PREFIXES="$HOME/.local/share/wineprefixes"
