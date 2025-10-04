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

    WINE_ARCH=$(cat $WINE_PATH/.wine_arch)
    WINE_BRANCH=$(cat $WINE_PATH/.wine_branch)
    WINE_VERSION=$(cat $WINE_PATH/.wine_version)

    # We only want to export the variable, not set it
    export WINE_PATH
    export WINE_BINARIES=$WINE_PATH/opt/wine-${WINE_BRANCH}/bin
    export WINE_UTILS="$WINE_PATH/opt/wine-${WINE_BRANCH}"

    export WINEDLLPATH="$WINE_PATH/opt/wine-${WINE_BRANCH}"

    if [[ "$WINE_ARCH" == "i386" ]];
    then
        export WINELOADER="$WINE_BINARIES/wine"
        export WINEDLLPATH+="/lib/wine/i386-unix"
        
        export WINE_UTILS+="/lib/wine/i386-windows"

        #echo "$LD_LIBRARY_PATH" | grep -q "wine/i386-unix"
        #
        #if ! [[ "$?" == "0" ]];
        #then
        #    if ! [[ -v LD_LIBRARY_PATH ]];
        #    then
        #        export LD_LIBRARY_PATH="$WINE_PATH/opt/wine-${WINE_BRANCH}"
        #    else
        #        export LD_LIBRARY_PATH+=":$WINE_PATH/opt/wine-${WINE_BRANCH}"
        #    fi
        #
        #    export LD_LIBRARY_PATH+="/lib/wine/i386-unix"
        #fi

    else
        export WINELOADER="$WINE_BINARIES/wine64"
        export WINEDLLPATH+="/lib64/wine/x86_64-unix"
        
        export WINE_UTILS+="/lib64/wine/x86_64-windows"

        #echo "$LD_LIBRARY_PATH" | grep -q "wine/x86_64-unix"
        #
        #if ! [[ "$?" == "0" ]];
        #then
        #    if ! [[ -v LD_LIBRARY_PATH ]];
        #    then
        #        export LD_LIBRARY_PATH="$WINE_PATH/opt/wine-${WINE_BRANCH}"
        #    else
        #        export LD_LIBRARY_PATH+=":$WINE_PATH/opt/wine-${WINE_BRANCH}"
        #    fi
        #
        #    export LD_LIBRARY_PATH+="/lib64/wine/x86_64-unix"
        #fi
    fi

    # Needed by winetricks
    export WINE="$WINELOADER"

    export WINESERVER="$WINE_BINARIES/wineserver"
    
    # The aliases will be available for the current shell session
    # but not for the other scripts. They will include wine_cmds
    # instead.

    alias wine="$WINELOADER"
    alias wineboot="\"$WINELOADER\" \"$WINE_UTILS/wineboot.exe\""
    alias winecfg="\"$WINELOADER\" \"$WINE_UTILS/winecfg.exe\""
    alias winedump="\"$WINE_BINARIES/winedump\""
    alias winefile="\"$WINELOADER\" \"$WINE_UTILS/winefile.exe\""
    alias reg="\"$WINELOADER\" \"$WINE_UTILS/reg.exe\""
    alias regedit="\"$WINELOADER\" \"$WINE_UTILS/regedit.exe\""

    # Make also available the wine-env commands.
    #source $HOME/.wine_env

    echo "Activated Wine $WINE_BRANCH ($WINE_VERSION): $WINE_PATH"
    echo ""
fi
