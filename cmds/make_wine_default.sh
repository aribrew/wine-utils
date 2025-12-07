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

    if ! [[ -f "$WINE_INSTALL/.wine_version" ]];
    then
        echo -e "Not valid WINE installation at '$WINE_INSTALL'.\n"
    else
        WINE_INSTALL=$(basename "$WINE_INSTALL")
    
        echo "$WINE_ENV/$WINE_INSTALL" > "$WINE_ENV/.default_wine"

        echo -e "WINE installation at '$WINE_INSTALL' made the default one."
        echo -e "It will be loaded for preparing new prefixes.\n"
    fi
fi
