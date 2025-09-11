#!/bin/bash

BASH_HELPERS="/opt/bin/bash_helpers.sh"


if ! [[ -f "$BASH_HELPERS" ]];
then
    echo "Cannot find '$BASH_HELPERS'."
    echo ""

    exit 1
    
else
    source "$BASH_HELPERS"
fi


install_activator()
{
    WINE_PREFIX=$1
    WINE_ARCH=$2

    if ! [[ -d "$WINE_PREFIX/dosdevices" ]];
    then
        echo -e "Invalid WINE prefix '$WINE_PREFIX'\n" && exit 1
    fi
    
    if ! [[ -f "$WINE_ENV/for_prefixes/.activate_prefix" ]];
    then
        echo "Cannot create activator for prefix '$WINE_PREFIX'."
        echo -e "Template not found.\n" && exit 1
    fi
        
    ACTIVATOR=$WINE_PREFIX/activate

    cp "$WINE_ENV/for_prefixes/.activate_prefix" "$ACTIVATOR"

    sed -i "s|WINEPREFIX_PLACEHOLDER|$WINE_PREFIX|g" "$ACTIVATOR"
    sed -i "s|WINEARCH_PLACEHOLDER|$WINE_ARCH|g" "$ACTIVATOR"

    chmod +x "$ACTIVATOR"

    echo "$WINE_PREFIX" > /tmp/.last_active_wine_prefix

    echo ""
    echo "Activator installed for prefix '$WINE_PREFIX'."
    echo "Execute '. $WINE_PREFIX/activate' for activate this prefix."
    echo ""
}


install_defaulter()
{
    WINE_PREFIX=$1

    if ! [[ -d "$WINE_PREFIX/dosdevices" ]];
    then
        echo -e "Invalid WINE prefix '$WINE_PREFIX'\n" && exit 1
    fi
    
    if ! [[ -f "$WINE_ENV/for_prefixes/.make_prefix_default" ]];
    then
        echo "Cannot create defaulter for prefix '$WINE_PREFIX'."
        echo -e "Template not found.\n" && exit 1
    fi
        
    DEFAULTER="$WINE_PREFIX/make_default"

    cp "$WINE_ENV/for_prefixes/.make_prefix_default" "$DEFAULTER"
    chmod +x "$DEFAULTER"

    echo ""
    echo "Execute '$WINE_PREFIX/make_default' for set this prefix as the"
    echo "default one for 32 or 64 bits apps (depending of its architecture)."
    echo ""
}


setup_prefix()
{
    WINE_PREFIX=$1
    WINE_ARCH=$2

    echo "Initializing $WINE_ARCH prefix '$WINE_PREFIX' ..."
    echo ""

    if ! [[ -v WINELOADER ]];
    then
        echo "No WINE environment loaded detected."
        abort "Load one with '. wine_load <WINE path>' first."
    fi

    "$WINELOADER" "$WINE_UTILS/wineboot.exe"

    if ! [[ "$?" == "0" ]];
    then
        abort "Initialization failed. Maybe a permissions problem."
    fi

    install_activator "$WINE_PREFIX" $WINE_ARCH
    install_defaulter "$WINE_PREFIX"
}


usage()
{
    echo "Usage: win_prepare [prefix name] [win32|win64]"
    echo ""
    echo "Setups a new Wine prefix."
    echo ""
    echo "All WINE prefixes goes in ~/.local/share/wineprefixes by default."
    echo "To use another location, set it in WIN_ROOT environment variable."
    echo "If no architecture is selected, win64 is used by default."
    echo ""
    echo "If an existing prefix is detected, and no activator is found there,"
    echo "one new will be created."
    echo ""
    echo "If no prefix name is given, the default ones will be used."
    echo ""
}





if ! [[ -v WINE_ENV ]] && ! [[ -f "$WINE_ENV/.wine_env" ]];
then
    abort "WINE environment not loaded yet. Source .wine_env."
fi


if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    abort
fi


WINE_PREFIX=$1
WINE_ARCH=$2


if [[ "$WINE_PREFIX" == "" ]];
then
    WINE_PREFIX=".wine64"
    WINE_ARCH="win64"

elif [[ "$1" == "win32" ]] || [[ "$1" == ".wine" ]];
then
    WINE_PREFIX=".wine"
    WINE_ARCH="win32"

elif [[ "$1" == "win64" ]] || [[ "$1" == ".wine64" ]];
then
    WINE_PREFIX=".wine64"
    WINE_ARCH="win64"
fi


if [[ "$WINE_ARCH" == "" ]];
then
    echo "No architecture specified. Using Win64."
    WINE_ARCH="win64"
else
    if ! [[ "$WINE_ARCH" == "win32" ]] && ! [[ "$WINE_ARCH" == "win64" ]];
    then
        abort "Invalid architecture '$WINE_ARCH'. Must be win32 or win64."
    fi
fi


if [[ -v WIN_ROOT ]] && [[ -d "$WIN_ROOT" ]];
then
    echo "Using '$WIN_ROOT' as prefixes root."

    echo "Testing $WIN_ROOT for write permissions ..."
    touch "$WIN_ROOT/touched"

    if ! [[ "$?" == "0" ]];
    then
        abort "ERROR: Cannot write in '$WIN_ROOT'"
    else
        rm "$WIN_ROOT/touched"
        echo "All seems OK."
    fi
else
    if [[ "$WINE_PREFIX" == ".wine" ]] || [[ "$WINE_PREFIX" == ".wine64" ]];
    then
        export WIN_ROOT="$HOME"
    else
        export WIN_ROOT="$HOME/.local/share/wineprefixes"
    fi
fi


if ! [[ -d "$WIN_ROOT" ]];
then
    mkdir -p "$WIN_ROOT"
fi


echo "Checking if a prefix '$WINE_PREFIX' already exists in '$WIN_ROOT' ..."

if [[ -d "$WIN_ROOT/$WINE_PREFIX/dosdevices" ]];
then
    if [[ -d "$WIN_ROOT/$WINE_PREFIX/drive_c/Program Files (x86)" ]];
    then
        WINE_ARCH="win64"
    else
        WINE_ARCH="win32"
    fi

    if ! [[ -f "$WIN_ROOT/$WINE_PREFIX/activate" ]];
    then
        echo "The prefix exists but no activator was found."
        install_activator "$WIN_ROOT/$WINE_PREFIX" $WINE_ARCH
    fi

    if ! [[ -f "$WIN_ROOT/$WINE_PREFIX/make_default" ]];
    then
        install_defaulter "$WIN_ROOT/$WINE_PREFIX"
    fi

else
    setup_prefix "$WIN_ROOT/$WINE_PREFIX" $WINE_ARCH
fi
