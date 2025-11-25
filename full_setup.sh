#!/bin/bash

SCRIPT_HOME=$(realpath $(dirname $0))


if ! [[ -v BASH_HELPERS_LOADED ]];
then
    # Tell us where is, or should be, the bash_helpers.sh script
    BASH_HELPERS=$("$SCRIPT_HOME/bash_helpers.sh" --path)

    if [[ -f "$BASH_HELPERS" ]];
    then
        "$SCRIPT_HOME/bash_helpers.sh" --install
    fi
    
    source "$SCRIPT_HOME/bash_helpers.sh"
fi


"$SCRIPT_HOME/update.sh"


"$SCRIPT_HOME/install_requirements.sh"


check_if_admin

if [[ -v SUPER_USER ]];
then
    WINE_ENV_PATH="/opt/winenv"
else
    WINE_ENV_PATH="$HOME/.local/bin/winenv"
fi


if ! [[ -f "$WINE_ENV_PATH/.wine_env" ]];
then
    "$SCRIPT_HOME/install_winenv.sh"
fi


grep -q ".wine_env" "$HOME/.environment"

if ! [[ "$?" == "0" ]];
then
    echo "source $WINE_ENV_PATH/.wine_env" >> "$HOME/.environment"
fi


if ! [[ -v WINE_ENV ]];
then
    source "$WINE_ENV_PATH/.wine_env"
    
    WINE_INSTALLATIONS=$(find "$WINE_ENV/" -maxdepth 1 -type d -name "wine-*")

    if [[ "$WINE_INSTALLATIONS" == "" ]];
    then
        "$SCRIPT_HOME/install_wine_repo.sh"
        "$SCRIPT_HOME/install_wine_deps.sh"
        "$SCRIPT_HOME/install_wine.sh"
    fi
fi

