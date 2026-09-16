#!/bin/bash

SCRIPT_HOME=$(realpath $(dirname $0))


usage()
{
    echo "Usage: gog_game_id.sh <game name|URL>"
    echo ""
    echo "The game name must be one of the entries of the catalog."
    echo "You can provide the full name or part of it."
    echo "In the second case, only the last match is taken."
    echo ""
    echo "You can also provide the URL of the game in the GOG store."
    echo ""
}


OS=$(uname -a)

if [[ $OS == Linux* ]];
then
    GOGG="lgogg"

elif [[ $OS == Darwin ]];
then
    GOGG="mgogg"
else
    echo -e "No Linux or Mac... what the hell is this?\n"
    exit -1
fi


if ! [[ -f "$SCRIPT_HOME/$GOGG" ]];
then
    echo -e "Cannot find $GOGG executable. Must be along the script.\n"
    exit 1
fi


if [[ "$1" == "" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    exit 1
fi


export PATH=$SCRIPT_HOME:$PATH


GAME_NAME="$1"

if [[ $GAME_NAME == https* ]];
then
    GAME_URL="$GAME_NAME"
    GAME_ID=$(curl $GAME_URL | grep '"sku":')

    if ! [[ "$GAME_ID" == "" ]];
    then
        GAME_ID=$(echo "$GAME_ID" | xargs | sed 's/,/g' | cut -d ' ' -f 2)
    fi
else
    GAME_ID=$($GOGG catalogue search "$GAME_NAME" 2> /dev/null | grep "$GAME_NAME" | tail -1 | cut -d "|" -f 3 | xargs)
fi

echo "$GAME_ID"
