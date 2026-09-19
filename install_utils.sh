#!/bin/bash

SCRIPT_HOME=$(realpath $(dirname $0))

source "$SCRIPT_HOME/wine_helpers"


INSTALL_PATH="$HOME/.local/bin/wine"


if [[ -f "$INSTALL_PATH/wine_load.sh" ]];
then
    mkdir -p "$INSTALL_PATH"
fi


echo -e "Updating WINE Utils ...\n"
echo -e "-----------------------"

cp -u "$SCRIPT_HOME/twine.sh" "$INSTALL_PATH"/
cp -u "$SCRIPT_HOME/wine.sh" "$INSTALL_PATH"/
cp -u "$SCRIPT_HOME/wine_"* "$INSTALL_PATH"/
cp -u "$SCRIPT_HOME/wineprefix_"* "$INSTALL_PATH"/
cp -u "$SCRIPT_HOME/winenv_load.sh" "$INSTALL_PATH"/
cp -u "$SCRIPT_HOME/make_default_wine.sh" "$INSTALL_PATH"/
cp -u "$SCRIPT_HOME/install.sh" "$INSTALL_PATH"/

cp -ru "$SCRIPT_HOME/docs" "$INSTALL_PATH"/
cp -ru "$SCRIPT_HOME/extras" "$INSTALL_PATH"/
cp -ru "$SCRIPT_HOME/gog" "$INSTALL_PATH"/

cp -u "$SCRIPT_HOME/.wine_utils.paths" "$HOME"/

echo -e "Done.\n"
echo -e "Add 'source \$HOME/.wine_utils.paths' to your .bashrc or"
echo -e ".environment file if you haven't done yet.\n"
