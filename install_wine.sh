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


mktree()
{
    $SUDO mkdir -p $*
}


source bash_helpers.sh

if ! [[ -v BASH_HELPERS_LOADED ]];
then
    echo -e "BASH Helpers not found in PATH. Install them first.\n"
    exit 1
fi


WINE_PATH=$1

if [[ "$2" == "--system" ]];
then
    WINE_ENV_PATH="/opt/winenv"
    SUDO="sudo"
else
    WINE_ENV_PATH="$HOME/.local/bin/winenv"
fi


if [[ -f "${WINE_PATH}/.wine_branch" ]]; 
then
    WINE_FOLDER=$(basename "$WINE_PATH")
	
    WINE_ARCH=$(cat "$WINE_PATH/.wine_arch")
    WINE_BRANCH=$(cat "$WINE_PATH/.wine_branch")
    WINE_VERSION=$(cat "$WINE_PATH/.wine_version")

    if [[ -d "$WINE_ENV_PATH/$WINE_FOLDER" ]]; 
    then
        abort "This WINE version is already installed."
    fi

    echo -n "Installing WINE $WINE_VERSION ($WINE_BRANCH) for $WINE_ARCH "
    echo "in '$WINE_ENV_PATH' ..."
    echo "--------------------------------------------------------------------"

    if ! [[ -d "$WINE_ENV_PATH" ]]; 
    then
        mktree "$WINE_ENV_PATH"
    fi

    copy -r "$WINE_PATH" "$WINE_ENV_PATH"

    if [[ "$WINE_ARCH" == "i386" ]] && ! [[ -f "$WINE_ENV_PATH/.default_wine32" ]]; 
    then
        echo "$WINE_ENV_PATH/$WINE_FOLDER" > "$WINE_ENV_PATH/.default_wine32"

        echo "'$WINE_ENV_PATH/$WINE_FOLDER' is now the default for 32 bits."
        echo ""

    elif [[ "$WINE_ARCH" == "amd64" ]] && ! [[ -f "$WINE_ENV_PATH/.default_wine64" ]]; 
    then
        echo "$WINE_ENV_PATH/$WINE_FOLDER" > "$WINE_ENV_PATH/.default_wine64"

        echo "'$WINE_ENV_PATH/$WINE_FOLDER' is now the default for 64 bits."
        echo ""
    fi
    
    grep -q ".wine_env" "$HOME/.environment"

    if ! [[ "$?" == "0" ]]; 
    then
        echo "source $WINE_ENV_PATH/.wine_env" >> "$HOME/.environment"
    fi

    echo "Done."
fi
