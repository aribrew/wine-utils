#!/bin/bash

SCRIPT_HOME=$(realpath $(dirname $0))


if ! [[ -v BASH_HELPERS_LOADED ]];
then
    # Tell us where is, or should be, the bash_helpers.sh script
    BASH_HELPERS=$("$SCRIPT_HOME/bash_helpers.sh" --path)

    if [[ -f "$BASH_HELPERS" ]];
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

