#!/bin/bash

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


SCRIPT_HOME=$(realpath $(dirname $0))




echo -e "Updating/installing WINE environment files.\n"


echo -e "Trying to update files with Github ...\n"
echo -e "----------------------------------------"

cd "$SCRIPT_HOME"

git pull


if ! [[ "$?" == "0" ]];
then
    echo -e "Failed syncing with the wine-utils repo."
    echo -e "Current version may be outdated.\n"
fi


if [[ "$HOME" == "/root" ]];
then
    echo -e "Running as admin. WINE environment in /opt/winenv.\n"

    WINE_ENV="/opt/winenv"
    export SUDO="sudo"
    
else
    echo -e "Running as user. WINE environment in ~/.local/bin/winenv.\n"
    WINE_ENV="$HOME/.local/bin/winenv"
fi


if ! [[ -d "$WINENV" ]];
then
    mktree "$WINENV"
fi


copy -u "$SCRIPTS/.wine_env" "$WINE_ENV/"

copy -ru "$SCRIPTS/cmds" "$WINE_ENV/"
copy -ru "$SCRIPTS/for_prefixes" "$WINE_ENV/"

copy -u "$SCRIPTS/download_wine.sh" "$WINE_ENV/"
copy -u "$SCRIPTS/install_wine.sh" "$WINE_ENV/"
copy -u "$SCRIPTS/install_winetricks.sh" "$WINE_ENV/"
copy -u "$SCRIPTS/make_prefix_autoload.sh" "$WINE_ENV/"
copy -u "$SCRIPTS/make_wine_autoload.sh" "$WINE_ENV/"



echo "WINE Utils scripts updated."
echo ""
