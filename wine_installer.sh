#!/bin/bash

WINE_PATH=$(realpath $(dirname $0))


usage()
{
    echo -e "Usage: installer.sh [install path]"
    echo -e ""
    echo -e "This script is meant to be part of a WINE installation."
    echo -e "When placed in the its top level (named 'installer.sh'),"
    echo -e "it provides a quick way for installing that WINE copy"
    echo -e "into ~/.local/bin/wine, or another path or your choice."
    echo -e ""
}


if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    exit 1
fi


if ! [[ "$WINE_PATH/.wine_version" ]];
then
    echo -e "This script only works at the root of a WINE tree.\n"
    exit 1
fi


if ! [[ "$1" == "" ]];
then
    INSTALL_PATH="$1"
else
    INSTALL_PATH="$HOME/.local/bin/wine"
fi


WINE_FOLDER=$(basename "$WINE_PATH")


if ! [[ -d "$INSTALL_PATH" ]];
then
    mkdir -p "$INSTALL_PATH"
fi


if [[ "$?" == "0" ]];
then
    echo -e "Cannot install in '$INSTALL_PATH'. Check your permissions.\n"
    exit 1
fi


echo -e "Installing '$WINE_FOLDER' into '$INSTALL_PATH'..."
cp -r "$WINE_PATH" "$INSTALL_PATH"/

if ! [[ "$?" == "0" ]];
then
    echo -e "Something failed.\n"
    exit 1
fi

echo -e "Done! Run 'make_default.sh' to make this WINE installation"
echo -e "the default one.\n"
