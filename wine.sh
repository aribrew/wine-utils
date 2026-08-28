#!/bin/bash

SCRIPT_HOME=$(realpath $(dirname $0))

source "$SCRIPT_HOME/wine_helpers"


usage()
{
    echo -e "Usage: \n"
    echo -e "wine.sh <exe path>"
    echo -e ": Executes the given Windows executable."
    echo -e "  If WORKDIR is given, we change to that dir before\n."
}


if [[ "$1" == "" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    abort
fi


EXEC="$1"
ARGS=${@:2}


if ! [[ -f "$EXEC" ]];
then
    abort "Cannot find '$EXEC'."
fi


if ! [[ -v WINEPREFIX ]];
then
    echo -e "No WINEPREFIX found loaded."
    echo -e "Will try loading the required default."

    EXEC_TYPE=$(exec_type "$EXEC")

    if [[ "$EXEC_TYPE" == "windows-i386" ]];
    then
        PREFIX="$HOME/.wine"

    elif [[ "$EXEC_TYPE" == "windows-amd64" ]];
    then
        PREFIX="$HOME/.wine64"
    fi

    if [[ -v PREFIX ]] && [[ -d "$PREFIX" ]];
    then
        source wine_load.sh "$PREFIX"
    else
        abort "Cannot find a WINE prefix for $EXEC_TYPE executables."
    fi
fi


if ! [[ -v WINELOADER ]];
then
    echo -e "No WINE installation loaded found."
    echo -e "Will try loading the default one."

    DEFAULT_WINE_VERSION="11.0.0.0"
    DEFAULT_WINE_PATH="$HOME/.local/bin/wine-${DEFAULT_WINE_VERSION}"

    if [[ -d "$DEFAULT_WINE_PATH" ]];
    then
        is_wine_installation "$DEFAULT_WINE_PATH"

        if ! [[ "$?" == "0" ]];
        then
            echo -e "Found 'wine-${DEFAULT_WINE_VERSION}' at ~/.local/bin, "
            echo -e "but isn't a valid WINE installation."

            abort
        fi

        source wine_load.sh "$DEFAULT_WINE_PATH"
    fi
fi


if [[ -v WORKDIR ]];
then
    if [[ -d "$WORKDIR" ]];
    then
        abort "A WORKDIR was provided, but cannot find it."
    fi

    cd "$WORKDIR"
fi


if [[ "$EXEC" == "config" ]];
then
    "$WINELOADER" winecfg

elif [[ "$EXEC" == "explorer" ]];
then
    "$WINELOADER" explorer

else
    EXEC_PATH=$(dirname $(realpath "$EXEC"))
    EXEC_FILENAME=$(basename "$EXEC_PATH")

    cd "$EXEC_PATH"

    echo -e "[DEBUG] Running $WINELOADER $EXEC_FILENAME $ARGS ..."

    "$WINELOADER" "$EXEC_FILENAME" $ARGS
fi
