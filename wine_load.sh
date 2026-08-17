#!/bin/bash

SCRIPT_HOME=$(realpath $(dirname $0))

source "bash_helpers"


load_wine()
{
    local WINE_PATH="$1"

    if ! [[ "$WINE_PATH" == "" ]];
    then
        echo -e "Trying loading WINE installation at '$WINE_PATH'...\n"
    else
        echo -e "Trying loading default WINE...\n"

        if [[ -f "$HOME/.default_wine" ]];
        then
            WINE_PATH=$(cat "$HOME/.default_wine")
        else
            abort "Unable to load WINE. No installation set as the default."
        fi
    fi

    is_wine_installation "$WINE_PATH"

    if ! [[ "$?" == "0" ]];
    then
        abort "No WINE installation found at '$WINE_PATH'."
    fi

    if ! [[ -v WINEARCH ]];
    then
        if [[ -v WINEPREFIX ]];
        then
            if [[ -f "$WINEPREFIX/.arch" ]];
            then
                WINEARCH=$(cat "$WINEPREFIX/.arch")
            else
                if [[ -d "$WINEPREFIX/drive_c/Program Files (x86)" ]];
                then
                    export WINEARCH="win64"
                else
                    export WINEARCH="win32"
                fi
            fi
        else
            abort "No WINE prefix loaded. Load one first."
        fi
    fi

    if [[ -f "$WINE_PATH/.wine_branch" ]];
    then
        WINE_BRANCH=$(cat "$WINE_PATH/.wine_branch")
    fi

    if [[ -f "$WINE_PATH/.wine_version" ]];
    then
        WINE_VERSION="("
        WINE_VERSION+=$(cat "$WINE_PATH/.wine_version")
        WINE_VERSION+=")"
    fi

    export WINE_BINARIES=$(find "$WINE_PATH"/** -type d -name "bin")
    export WINE_ROOT=$(dirname "$WINE_BINARIES")

    WINE_MAJOR_VERSION=$(cat "$WINE_PATH/.wine_version")
    WINE_MAJOR_VERSION=$(echo "$WINE_MAJOR_VERSION" | cut -d '.' -f 1)

    if ! [[ "$WINE_MAJOR_VERSION" == "11" ]];
    then
        if [[ "$WINEARCH" == "win32" ]];
        then
            export WINELOADER="$WINE_BINARIES/wine"
            export WINEDLLPATH="$WINE_ROOT/lib/wine"

            export WINE32_UTILS="$WINE_ROOT/lib/wine/i386-windows"
            export WINE_UTILS="$WINE32_UTILS"
            export WINE_ARCH="win32"
        else
            export WINELOADER="$WINE_BINARIES/wine64"
            export WINEDLLPATH="$WINE_DLL_PATH/lib64/wine"

            export WINE64_UTILS="$WINE_ROOT/lib64/wine/x86_64-windows"
            export WINE_UTILS="$WINE64_UTILS"
            export WINE_ARCH="win64"
        fi
    else
        export WINELOADER="$WINE_BINARIES/wine"
        export WINEDLLPATH="$WINE_ROOT/lib/wine"

        export WINE32_UTILS="$WINE_ROOT/lib/wine/i386-windows"
        export WINE64_UTILS="$WINE_ROOT/lib/wine/x86_64-windows"

        if [[ "$WINEARCH" == "win32" ]];
        then
            export WINE_UTILS="$WINE32_UTILS"
        else
            export WINE_UTILS="$WINE64_UTILS"
        fi

        export WINE_ARCH="both"
    fi

    export WINE="$WINELOADER"
    export WINESERVER="$WINE_BINARIES/wineserver"
    export WINEDEBUG="-all"

    alias wine="$WINELOADER"

    if ! [[ "$WINE_MAJOR_VERSION" == "11" ]];
    then
        alias wine32="$WINE_BINARIES/wine"
        alias wine64="$WINE_BINARIES/wine64"
    fi

    alias wineboot="\"$WINELOADER\" \"$WINE_UTILS/wineboot.exe\""
    alias winecfg="\"$WINELOADER\" \"$WINE_UTILS/winecfg.exe\""
    alias winedump="\"$WINE_BINARIES/winedump\""
    alias cmd="\"$WINELOADER\" \"$WINE_UTILS/cmd.exe\""
    alias explorer="\"$WINELOADER\" \"$WINE_UTILS/winefile.exe\""
    alias reg="\"$WINELOADER\" \"$WINE_UTILS/reg.exe\""
    alias regedit="\"$WINELOADER\" \"$WINE_UTILS/regedit.exe\""

    echo "Activated Wine $WINE_BRANCH $WINE_VERSION: $WINE_PATH"

    if [[ "$WINEARCH" == "win32" ]];
    then
        echo "Loaded a 32 bit environment."
    else
        echo "Loaded a 64 bit environment."
    fi

    echo ""
    echo "You have available the following aliases: "

    if ! [[ "$WINE_MAJOR_VERSION" == "11" ]];
    then
        echo "- wine: Default WINE executable for the loaded prefix"
        echo "- wine32: WINE executable for 32 bit software"
        echo "- wine64: WINE executable for 64 bit software"
    else
        echo "- wine: WINE executable"
    fi

    echo "- wineboot: Performs a 'reboot' of the loaded prefix."
    echo "- explorer, reg, regedit: Launch these Windows programs."
    echo ""
    echo "Also, if you want to see debug information, unset WINEDEBUG."

    if [[ "$WINE_MAJOR_VERSION" == "11" ]] && [[ "$WINEARCH" == "win32" ]];
    then
        echo -e "\nYou are using a win32 prefix with WINE 11."
        echo -e "This mean this prefix will make use of WOW64, and this"
        echo -e "may not be compatible with some software."
        echo -e ""
        echo -e "If you encounter problems with 32 bits apps, you can try"
        echo -e "installing and loading WINE 10 (10.0.0.0) and you will be"
        echo -e "able to create pure win32 prefixes."
    fi

    echo ""
}


usage()
{
    echo -e "Usage: \n"
    echo -e "wine_load.sh [WINE path]"
    echo -e ": Load the given WINE installation."
    echo -e "  If none is provided, loads the default one."
}


if [[ "$1" == "" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    abort
fi
