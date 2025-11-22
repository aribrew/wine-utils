#!/bin/bash

source bash_helpers.sh

if ! [[ -v BASH_HELPERS_LOADED ]];
then
    echo -e "BASH helpers not found in PATH. Install it first.\n"
    exit 1
fi


if ! [[ -v WINE_ENV ]];
then
    abort "WINE environment has not been loaded yet."
fi


if ! [[ -v WINELOADER ]];
then
    abort "You need a WINE installation loaded before doing this."
fi


if ! [[ -v WINEPREFIX ]];
then
    abort "A WINE prefix needs to be loaded."
fi


"$WINELOADER" "$WINE_ENV/extras/nGlide v2.1.0.exe"

