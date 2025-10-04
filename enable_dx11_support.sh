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
echo "Installing DXVK (DirectX -> Vulkan) for DirectX 11 compatibility..."
echo "-------------------------------------------------------------------"

winetricks dxvk

if [[ "$?" == "0" ]];
then
    touch "$WINEPREFIX/.dx11_enabled"
fi
