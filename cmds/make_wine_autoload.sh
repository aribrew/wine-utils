#!/bin/bash

if ! [[ WINE_ENV ]];
then
    echo "No WINE environment loaded."
    echo ""

    exit 1
fi


if [[ "$1" == "" ]] || ! [[ -f "$1/.wine_version" ]];
then
    echo "No valid WINE installation provided."
    echo ""

    exit 1
else
    WINE_INSTALL="$1"
    
    echo "$WINE_INSTALL" > "$WINE_ENV/.auto_load"

    echo "WINE installation at '$WINE_INSTALL' will now auto-load."
    echo ""
fi
