#!/bin/bash

################################################################
# Installs the specified WINE folder in ~/.local/bin/winenv.
# This is done this way to avoid colliding with existing WINE
# system-wide installations.
################################################################

BASH_HELPERS="/opt/bin/bash_helpers"
SCRIPTS=$(realpath $(dirname $0))


if ! [ -f "$BASH_HELPERS" ] &&
     [ -f "$SCRIPTS/bash_helpers" ];
then
    "$SCRIPTS/helpers/bash_helpers" install
fi


if ! [ -f "$BASH_HELPERS" ];
then
    echo "Cannot find '$BASH_HELPERS'."
    echo ""

    exit 1
    
else
    source "$BASH_HELPERS"
fi




WINE_PATH=$1
INSTALL_PATH="$HOME/.local/bin/winenv"


if [ -f "${WINE_PATH}/.wine_branch" ];
then
    WINE_FOLDER=$(basename "$WINE_PATH")
	
    WINE_ARCH=$(cat "$WINE_PATH/.wine_arch")
    WINE_BRANCH=$(cat "$WINE_PATH/.wine_branch")
    WINE_VERSION=$(cat "$WINE_PATH/.wine_version")

    if [ -d "$INSTALL_PATH/$WINE_FOLDER" ];
    then
        abort "This WINE version is already installed."
    fi

    echo -n "Installing WINE $WINE_VERSION ($WINE_BRANCH) for $WINE_ARCH "
    echo "in '$INSTALL_PATH' ..."
    echo "--------------------------------------------------------------------"

    if ! [ -d "$INSTALL_PATH" ];
    then
        mkdir -p "$INSTALL_PATH"
    fi

    cp -r "$WINE_PATH" "$INSTALL_PATH"
    cp -r "$SCRIPTS/cmds" "$INSTALL_PATH/"

    cp "$SCRIPTS/.wine_env" "$INSTALL_PATH/"

    if [ "$WINE_ARCH" == "i386" ] && ! [ -f "$INSTALL_PATH/.default_wine32" ];
    then
        echo "$INSTALL_PATH/$WINE_FOLDER" > "$INSTALL_PATH/.default_wine32"

        echo "'$INSTALL_PATH/$WINE_FOLDER' is now the default for 32 bits."
        echo ""

    elif [ "$WINE_ARCH" == "amd64" ] && ! [ -f "$INSTALL_PATH/.default_wine64" ];
    then
        echo "$INSTALL_PATH/$WINE_FOLDER" > "$INSTALL_PATH/.default_wine64"

        echo "'$INSTALL_PATH/$WINE_FOLDER' is now the default for 64 bits."
        echo ""
    fi
    
    grep -q ".wine_env" "$HOME/.environment"

    if ! [ "$?" == "0" ];
    then
        echo "source $INSTALL_PATH/.wine_env" >> "$HOME/.environment"
    fi

    echo "Done."
fi
