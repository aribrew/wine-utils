#!/bin/bash

SCRIPT_HOME=$(realpath $(dirname $0))


usage()
{
    echo "Usage: gog_game_id.sh <game name>"
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
GAME_ID=$(gogg catalogue search "$GAME_NAME" 2> /dev/null | grep "$GAME_NAME" | tail -1 | cut -d "|" -f 3 | xargs)

echo "$GAME_ID"
