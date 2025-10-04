#!/bin/bash

copy()
{
    $SUDO cp $*
}


mktree()
{
    TREE="$1"
    
    $SUDO mkdir -p "$TREE"
}


source bash_helpers.sh

if ! [[ -v BASH_HELPERS_LOADED ]];
then
    echo -e "BASH helpers not found in PATH. Install it first.\n"
    exit 1
fi


SCRIPT_HOME=$(realpath $(dirname $0))




echo -e "Updating/installing WINE environment files.\n"


echo -e "Trying to update files with Github ..."
echo -e "--------------------------------------"

cd "$SCRIPT_HOME"

git pull


if ! [[ "$?" == "0" ]];
then
    echo -e "Failed syncing with the wine-utils repo."
    echo -e "Current version may be outdated.\n"
fi


echo ""

if [[ "$HOME" == "/root" ]];
then
    echo -e "Running as admin. WINE environment in /opt/winenv."

    WINE_ENV="/opt/winenv"
    export SUDO="sudo"
    
else
    echo -e "Running as user. WINE environment in ~/.local/bin/winenv."
    WINE_ENV="$HOME/.local/bin/winenv"
fi


if ! [[ -d "$WINE_ENV" ]];
then
    mktree "$WINE_ENV"
fi


copy -u "$SCRIPT_HOME/.wine_env" "$WINE_ENV/"

copy -ru "$SCRIPT_HOME/cmds" "$WINE_ENV/"
copy -ru "$SCRIPT_HOME/for_prefixes" "$WINE_ENV/"

copy -u "$SCRIPT_HOME/download_wine.sh" "$WINE_ENV/"
copy -u "$SCRIPT_HOME/enable_dx11_support.sh" "$WINE_ENV/"
copy -u "$SCRIPT_HOME/enable_dx12_support.sh" "$WINE_ENV/"
copy -u "$SCRIPT_HOME/install_wine.sh" "$WINE_ENV/"
copy -u "$SCRIPT_HOME/install_winetricks.sh" "$WINE_ENV/"
copy -u "$SCRIPT_HOME/make_prefix_autoload.sh" "$WINE_ENV/"
copy -u "$SCRIPT_HOME/make_wine_autoload.sh" "$WINE_ENV/"



echo "WINE Utils scripts updated."
echo ""
