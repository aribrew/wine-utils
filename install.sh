#!/bin/bash

SCRIPT_HOME=$(realpath $(dirname $0))

usage()
{
    echo -e "Usage: \n"
    echo -e "install.sh [path]"
    echo -e ": Installs the helpers."
    echo -e "  If no path is given, ~/.local/bin/wine will be used."
}


if ! [[ -d "$HOME/.local/bin" ]];
then
    mkdir -p "$HOME/.local/bin"
    export PATH=$HOME/.local/bin:$PATH
fi


if ! [[ -f "$HOME/.local/bin/bash_helpers" ]] &&
   ! [[ -f "/opt/bin/bash_helpers" ]];
then
    cp "$SCRIPT_HOME/bash_helpers" "$HOME/.local/bin/"
fi


if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    exit 1
fi


if [[ "$1" == "" ]];
then
    INSTALL_PATH="$HOME/.local/bin/wine"
else
    INSTALL_PATH="$1"
fi


if ! [[ -d "$INSTALL_PATH" ]];
then
    mkdir -p "$INSTALL_PATH"

    cp -u "$SCRIPT_HOME/wine_"* "$INSTALL_PATH"/
    cp -u "$SCRIPT_HOME/wineprefix_"* "$INSTALL_PATH"/
    cp -u "$SCRIPT_HOME/make_"* "$INSTALL_PATH"/
    cp -u "$SCRIPT_HOME/wine.sh" "$INSTALL_PATH"/
    cp -ru "$SCRIPT_HOME/docs"* "$INSTALL_PATH"/
    cp -ru "$SCRIPT_HOME/extras"* "$INSTALL_PATH"/
fi
