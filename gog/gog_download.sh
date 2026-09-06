#!/bin/bash

SCRIPT_HOME=$(realpath $(dirname $0))

DOWNLOAD_PATH="$HOME/tmp"
PREFERRED_LANGUAGE="es"
INCLUDE_EXTRAS="false"


usage()
{
    echo "Usage: gog_download.sh <game name>"
    echo ""
    echo "The game name must be one of the entries of the catalog."
    echo ""
}


if ! [[ -f "$SCRIPT_HOME/gogg" ]];
then
    echo -e "Cannot find gogg executable. Must be along the script.\n"
    exit 1
fi


if [[ "$1" == "" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    exit 1
fi


export PATH=$SCRIPT_HOME:$PATH


GAME_NAME="$1"


GAME_ID=$(gog_game_id.sh "$GAME_NAME")

if [[ "$GAME_ID" == "" ]];
then
    echo -e "Cannot find game '$GAME_NAME'.\n"
    exit 1
fi


if ! [[ -d "$DOWNLOAD_PATH" ]];
then
    mkdir -p "$DOWNLOAD_PATH"
fi


gogg download $GAME_ID "$DOWNLOAD_PATH" --extras="$INCLUDE_EXTRAS" \
                                        --resume="true" \
                                        --lang="$PREFERRED_LANGUAGE"
