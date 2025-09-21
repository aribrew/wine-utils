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


source "$SCRIPT_HOME/update.sh"
