#!/bin/bash

copy()
{
    $SUDO cp $*
}


BASH_HELPERS="/opt/bin/bash_helpers.sh"

if ! [[ -f "$BASH_HELPERS" ]]; 
then
    echo "Cannot find '$BASH_HELPERS'."
    echo ""

    exit 1
    
else
    source "$BASH_HELPERS"
fi




if ! [[ -v WINE_ENV ]] && ! [[ -f "$WINE_ENV/.wine_env" ]];
then
    abort "WINE environment not loaded yet. Source .wine_env."
fi


SCRIPTS=$(realpath $(dirname $0))


touch "$WINE_ENV/testing"

if ! [[ "$?" == "0" ]];
then
    sudo touch "$WINE_ENV/testing"

    if ! [[ "$?" == "0" ]];
    then
        abort "WTF... Cannot write in '$WINE_ENV'!"
    else
        export SUDO="sudo"
        sudo rm "$WINE_ENV/testing"
    fi
else
    export SUDO=""
    rm "$WINE_ENV/testing"
fi


copy -ru "$SCRIPTS/cmds" "$WINE_ENV/"
copy -ru "$SCRIPTS/for_prefixes" "$WINE_ENV/"

copy -u "$SCRIPTS/download_wine.sh" "$WINE_ENV/"
copy -u "$SCRIPTS/install_wine.sh" "$WINE_ENV/"
copy -u "$SCRIPTS/install_winetricks.sh" "$WINE_ENV/"
copy -u "$SCRIPTS/make_prefix_autoload.sh" "$WINE_ENV/"
copy -u "$SCRIPTS/make_wine_autoload.sh" "$WINE_ENV/"

copy -u "$SCRIPTS/.wine_env" "$WINE_ENV/"


echo "WINE Utils scripts updated."
echo ""
