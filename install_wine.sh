#!/bin/bash

################################################################
# Installs the specified WINE folder in ~/.local/bin/winenv.
#
# This is done this way to avoid colliding with existing WINE
# system-wide installations.
#
# If a second paramenter, --system, is passed, the path
# /opt/winenv will be used instead.
#
# If both installation types are present, local one is used.
################################################################


copy()
{
    $SUDO cp $*
}


install_wine_from()
{
    WINE_PATH=$1

    if [[ -f "${WINE_PATH}/.wine_branch" ]]; 
    then
        WINE_FOLDER=$(basename "$WINE_PATH")
        
        WINE_ARCH=$(cat "$WINE_PATH/.wine_arch")
        WINE_BRANCH=$(cat "$WINE_PATH/.wine_branch")
        WINE_VERSION=$(cat "$WINE_PATH/.wine_version")

        echo ""
        echo -n "Installing WINE $WINE_VERSION ($WINE_BRANCH) for $WINE_ARCH "
        echo "in '$WINE_ENV' ..."
        echo "---------------------------------------------------------------"

        if ! [[ -d "$WINE_ENV" ]]; 
        then
            mktree "$WINE_ENV"
        fi

        copy -ru "$WINE_PATH" "$WINE_ENV/"

        if [[ "$WINE_ARCH" == "i386" ]] && 
         ! [[ -f "$WINE_ENV/.default_wine32" ]]; 
        then
            echo "$WINE_ENV/$WINE_FOLDER" > "$WINE_ENV/.default_wine32"

            echo "'$WINE_ENV/$WINE_FOLDER' is now the default for 32 bits."
            echo ""

        elif [[ "$WINE_ARCH" == "amd64" ]] && 
           ! [[ -f "$WINE_ENV/.default_wine64" ]]; 
        then
            echo "$WINE_ENV/$WINE_FOLDER" > "$WINE_ENV/.default_wine64"

            echo "'$WINE_ENV/$WINE_FOLDER' is now the default for 64 bits."
            echo ""
        fi
    fi
}


mktree()
{
    $SUDO mkdir -p $*
}


source bash_helpers.sh

if ! [[ -v BASH_HELPERS_LOADED ]];
then
    echo -e "BASH helpers not found in PATH. Install it first.\n"
    exit 1
fi


SCRIPT_HOME=$(realpath $(dirname $0))


WINE_PATH=$1


check_if_admin

if [[ -v SUPER_USER ]];
then
    export WINE_ENV="/opt/winenv"
    export SUDO="sudo"
else
    export WINE_ENV="$HOME/.local/bin/winenv"
fi

if ! [[ -f "$WINE_ENV/.wine_env" ]];
then
    echo -e "The file .wine_env was not found in '$WINE_ENV'."
    echo -e "Updating WINE environment first.\n"
    
    "$SCRIPT_HOME/update.sh"
fi


if [[ "$WINE_PATH" == "" ]];
then
    "$SCRIPT_HOME/download_wine.sh"

    if [[ "$?" == "0" ]];
    then
        if [[ -f "/tmp/.last_wine32_download" ]];
        then
            WINE32_PATH=$(cat "/tmp/.last_wine32_download")

            if [[ -f "$WINE32_PATH/.wine_version" ]];
            then
                install_wine_from "$WINE32_PATH"
            fi
        fi

        if [[ -f "/tmp/.last_wine64_download" ]];
        then
            WINE64_PATH=$(cat "/tmp/.last_wine64_download")

            if [[ -f "$WINE64_PATH/.wine_version" ]];
            then
                install_wine_from "$WINE64_PATH"
            fi
        fi
    fi
else
    install_wine_from "$WINE_PATH"
fi

