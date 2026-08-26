#!/bin/bash

SCRIPT_HOME=$(realpath $(dirname $0))

source "$SCRIPT_HOME/bash_helpers"
source "$SCRIPT_HOME/wine_helpers"


setup_prefix()
{
    export WINEPREFIX="$1"
    export WINEARCH="$2"

    echo -e "Preparing to setup a $WINEARCH prefix in '$WINEPREFIX'...\n"

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


PREFIX="$1"
PREFIX_ARCH="$2"


export WINE_PREFIXES="$HOME/.local/share/wineprefixes"


if ! [[ -d "$WINE_PREFIXES" ]];
then
    mkdir -p "$WINE_PREFIXES"
fi


if [[ "$PREFIX_ARCH" == "" ]];
then
    WINEARCH="win64"
fi


PREFIX_PATH=$(dirname "$PREFIX")

if [[ "$PREFIX_PATH" == "." ]];
then
    WINEPREFIX="$WINE_PREFIXES/$PREFIX"
else
    WINEPREFIX="$PREFIX"
fi

is_wine_prefix "$WINEPREFIX"

if [[ "$?" == "0" ]];
then
    abort "This prefix already exists."
fi


setup_prefix "$WINEPREFIX" "$WINEARCH"
