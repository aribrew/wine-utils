#!/bin/bash

################################################################
# Helps creating the needed environment variables in the current
# session for running WINE.
#
# Also creates some aliases for running WINE commands.
#################################################################

source bash_helpers.sh

if ! [[ -v BASH_HELPERS_LOADED ]];
then
    echo -e "BASH helpers not found in PATH. Install it first.\n"
    exit 1
fi


usage()
{
    echo "Usage: . wine_load <Wine installation path>"
    echo "       source wine_load <Wine installation path>"
    echo ""
    echo "Loads the specified Wine environment in the current shell session."
    echo ""
}




if [[ "$1" == "" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    abort
fi


WINE_PATH=$1


if ! [[ "$WINE_PATH" == "" ]];
then
    WINE_PATH=$(realpath "$WINE_PATH")
	
    if ! [[ -f "$WINE_PATH/.wine_version" ]];
    then
        abort "No Wine installation detected at '$WINE_PATH'."
    fi

    if ! [[ -v WINEARCH ]];
    then
        abort "A WINE prefix needs to be active first."
    fi
    
    WINE_BRANCH=$(cat $WINE_PATH/.wine_branch)
    WINE_VERSION=$(cat $WINE_PATH/.wine_version)

    # We only want to export the variable, not set it
    export WINE_PATH

    export WINE_BINARIES=$WINE_PATH/opt/wine-${WINE_BRANCH}/bin
    export WINE_UTILS=$WINE_PATH/opt/wine-${WINE_BRANCH}
    export WINE_DLL_PATH=$WINE_PATH/opt/wine-${WINE_BRANCH}

    WINE32_UTILS="$WINE_UTILS/lib/wine/i386-windows"
    WINE64_UTILS="$WINE_UTILS/lib64/wine/x86_64-windows"

    if [[ "$WINEARCH" == "win64" ]];
    then
        export WINELOADER="$WINE_BINARIES/wine64"
        export WINEDLLPATH="$WINE_DLL_PATH/lib64/wine"
        export WINE_UTILS="$WINE64_UTILS"
    else
        export WINELOADER="$WINE_BINARIES/wine"
        export WINEDLLPATH="$WINE_DLL_PATH/lib/wine"
        export WINE_UTILS="$WINE32_UTILS"
    fi

    # Needed by winetricks
    export WINE="$WINELOADER"
    export WINESERVER="$WINE_BINARIES/wineserver"
    
    
    # The aliases will be available for the current shell session
    # but not for the other scripts. They will include wine_cmds
    # instead

    alias wine="$WINELOADER"
    alias wine32="$WINE_BINARIES/wine"
    alias wine64="$WINE_BINARIES/wine64"

    alias wineboot="\"$WINELOADER\" \"$WINE_UTILS/wineboot.exe\""
    alias winecfg="\"$WINELOADER\" \"$WINE_UTILS/winecfg.exe\""
    alias winedump="\"$WINE_BINARIES/winedump\""
    alias cmd="\"$WINELOADER\" \"$WINE_UTILS/cmd.exe\""
    alias explorer="\"$WINELOADER\" \"$WINE_UTILS/winefile.exe\""
    alias reg="\"$WINELOADER\" \"$WINE_UTILS/reg.exe\""
    alias regedit="\"$WINELOADER\" \"$WINE_UTILS/regedit.exe\""

    echo "Activated Wine $WINE_BRANCH ($WINE_VERSION): $WINE_PATH"
    echo ""
    echo "You have available the following aliases: "
    echo "- wine: Default WINE executable for the loaded prefix"
    echo "- wine32: WINE executable for 32 bit software"
    echo "- wine64: WINE executable for 64 bit software"
    echo "- wineboot: Performs a 'reboot' of the loaded prefix."
    echo "- explorer, reg, regedit: Launch these Windows programs." 
    echo ""
fi
