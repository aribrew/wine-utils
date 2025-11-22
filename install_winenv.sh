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

read -p "Press ENTER to continue."


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


if ! [[ -d "$WINE_ENV" ]];
then
    mktree "$WINE_ENV"
fi


copy -u "$SCRIPT_HOME/.wine_env" "$WINE_ENV/"

copy -ru "$SCRIPT_HOME/cmds" "$WINE_ENV/"
copy -ru "$SCRIPT_HOME/extras" "$WINE_ENV/"
copy -ru "$SCRIPT_HOME/for_prefixes" "$WINE_ENV/"

copy -u "$SCRIPT_HOME/download_wine.sh" "$WINE_ENV/"
copy -u "$SCRIPT_HOME/install_wine.sh" "$WINE_ENV/"
copy -u "$SCRIPT_HOME/install_winetricks.sh" "$WINE_ENV/"
copy -u "$SCRIPT_HOME/make_prefix_autoload.sh" "$WINE_ENV/"
copy -u "$SCRIPT_HOME/make_wine_autoload.sh" "$WINE_ENV/"


if ! [[ -f "$HOME/.environment" ]];
then
    touch "$HOME/.environment"

    echo -e "\n\nsource \$HOME/.environment\n\n" >> "$HOME/.bashrc"
fi


grep -q ".wine_env" "$HOME/.environment"

if ! [[ "$?" == "0" ]];
then
    echo "source $WINE_ENV/.wine_env" >> "$HOME/.environment"
fi


echo -e "WINE environment installed/updated in '$WINE_ENV'."
echo -e "Remember to install a WINE version if not done yet.\n"
