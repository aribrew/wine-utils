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




SCRIPT_HOME=$(realpath $(dirname $0))


echo -e "Installing/updating WINE environment."
echo -e ""
echo -e "IMPORTANT: The WINE environment isn't WINE, but the environment"
echo -e "and the scripts we are using to help us using WINE itself.\n"


if [[ "$HOME" == "/root" ]];
then
    echo -e "Running as admin. WINE environment in /opt/winenv."
    echo -e "WINE environment will be in /opt/winenv\n"
    
    WINE_ENV="/opt/winenv"
    export SUDO="sudo"
    
else
    echo -e "Running as user."
    echo -e "WINE environment will be in ~/.local/winenv\n"
    
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


echo -e "WINE environment installed/updated in '$WINE_ENV'."
echo -e "Remember to install a WINE version if not done yet.\n"
