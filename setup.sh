#!/bin/bash

SCRIPT_HOME=$(realpath $(dirname $0))

if ! [[ -v BASH_HELPERS_LOADED ]];
then
    BASH_HELPERS_INSTALLED=$("$SCRIPT_HOME/bash_helpers.sh" --installed)

    if [[ "$BASH_HELPERS_INSTALLED" == "Helpers not found" ]];
    then
        "$SCRIPT_HOME/bash_helpers.sh --install"
    fi
    
    source "$SCRIPT_HOME/bash_helpers.sh"
fi


"$SCRIPT_HOME/update.sh"

if ! [[ -v WINE_ENV ]];
then
    WINE_INSTALLATIONS=$(find "$WINE_ENV/" -maxdepth 1 -type d -name "wine-*")

    if [[ "$WINE_INSTALLATIONS" == "" ]];
    then
        "$SCRIPT_HOME/install_wine_repo.sh"
        "$SCRIPT_HOME/install_deps.sh"
        "$SCRIPT_HOME/install_wine.sh"
    fi
fi

