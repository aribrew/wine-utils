#1/bin/bash

source bash_helpers.sh

if ! [[ -v BASH_HELPERS_LOADED ]];
then
    echo -e "BASH helpers not found in PATH. Install it first.\n"
    exit 1
fi


SCRIPT_HOME=$(realpath $(dirname $0))


if ! [[ -v WINE_ENV ]];
then
    abort "WINE environment has not been loaded yet."
fi


if ! [[ -v WINELOADER ]];
then
    abort "You need a WINE installation loaded before doing this."
fi


if [[ "$(which winetricks)" == "" ]];
then
    "$SCRIPT_HOME/install_winetricks.sh"

    if ! [[ "$?" == "0" ]];
    then
        abort "Winetricks installation failed. Cannot continue."
    fi
fi


echo ""
echo "Installing VKD3D for DirectX 12 compatibility..."
echo "------------------------------------------------"

winetricks vkd3d

if [[ "$?" == "0" ]];
then
    touch "$WINEPREFIX/.dx12_enabled"
fi
