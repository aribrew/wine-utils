#!/bin/bash

if ! [[ WINE_ENV ]];
then
    echo "No WINE environment loaded."
    echo ""

    exit 1
fi


if [[ "$1" == "" ]] || ! [[ -d "$1/dos_devices" ]];
then
    echo "No valid WINE prefix provided."
    echo ""

    exit 1
else
    WINE_PREFIX="$1"
    
    echo "$WINE_PREFIX" > "$WINE_ENV/.autoload_prefix"

    echo "WINE prefix at '$WINE_PREFIX' will now auto-load."
    echo ""
fi
