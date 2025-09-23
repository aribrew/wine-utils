#!/bin/bash

source bash_helpers.sh

if ! [[ -v BASH_HELPERS_LOADED ]];
then
    echo -e "BASH Helpers not found in PATH. Install them first.\n"
    exit 1
fi


check_valid_prefix()
{
    if ! [[ -v WINEPREFIX ]] || ! [[ -d "$WINEPREFIX/dosdevices" ]];
    then
        abort "Invalid WINE prefix '$WINEPREFIX'"
    fi
}


install_activator()
{
    check_valid_prefix
    
    if ! [[ -f "$WINE_ENV/for_prefixes/.activate_prefix" ]];
    then
        echo "Cannot create activator for prefix '$WINEPREFIX'."
        abort "Template not found."
    fi
        
    ACTIVATOR=$WINEPREFIX/activate

    cp "$WINE_ENV/for_prefixes/.activate_prefix" "$ACTIVATOR"

    sed -i "s|WINEPREFIX_PLACEHOLDER|$WINEPREFIX|g" "$ACTIVATOR"
    sed -i "s|WINEARCH_PLACEHOLDER|$WINEARCH|g" "$ACTIVATOR"

    chmod +x "$ACTIVATOR"

    echo "$WINEPREFIX" > /tmp/.last_active_wine_prefix
    
    echo "Activator installed for prefix '$WINEPREFIX'."
    echo "Execute '. $WINEPREFIX/activate' for activate this prefix."
    echo ""
}


install_defaulter()
{
    check_valid_prefix
    
    if ! [[ -f "$WINE_ENV/for_prefixes/.make_prefix_default" ]];
    then
        echo "Cannot create defaulter for prefix '$WINEPREFIX'."
        abort "Template not found."
    fi
        
    DEFAULTER="$WINEPREFIX/make_default"

    cp "$WINE_ENV/for_prefixes/.make_prefix_default" "$DEFAULTER"
    chmod +x "$DEFAULTER"

    echo "Execute '$WINEPREFIX/make_default' for set this prefix as the"
    echo "default one for 32 or 64 bits apps (depending of its architecture)."
    echo ""
}


setup_prefix()
{
    if ! [[ -v WINEPREFIX ]] || ! [[ -v WINEARCH ]];
    then
        echo -n "Both environment variables, WINEPREFIX and WINEARCH,"
        echo "must be set for setup a new prefix."

        abort
    fi

    echo "Initializing $WINEARCH prefix '$WINEPREFIX' ..."
    echo ""

    if ! [[ -v WINELOADER ]];
    then
        echo "No WINE environment loaded detected."
        abort "Load one with '. wine_load <WINE path>' first."
    fi

    "$WINELOADER" "$WINE_UTILS/wineboot.exe"

    if ! [[ "$?" == "0" ]];
    then
        echo -e "Initialization failed. Maybe a permissions problem.\n"
        exit 1
    fi

    echo "Prefix created. The helper scripts will be added now."
    echo ""

    install_activator
    install_defaulter
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


PREFIX_NAME="$1"
PREFIX_ARCH="$2"


if [[ "$PREFIX_NAME" == "" ]];
then
    PREFIX_NAME=".wine64"
    PREFIX_ARCH="win64"

elif [[ "$1" == "win32" ]] || [[ "$1" == ".wine" ]];
then
    PREFIX_NAME=".wine"
    PREFIX_ARCH="win32"

elif [[ "$1" == "win64" ]] || [[ "$1" == ".wine64" ]];
then
    PREFIX_NAME=".wine64"
    PREFIX_ARCH="win64"
fi


if [[ "$PREFIX_ARCH" == "" ]];
then
    echo "No architecture specified. Using Win64."
    PREFIX_ARCH="win64"
else
    if ! [[ "$PREFIX_ARCH" == "win32" ]] && ! [[ "$PREFIX_ARCH" == "win64" ]];
    then
        abort "Invalid architecture '$PREFIX_ARCH'. Must be win32 or win64."
    fi
fi


if ! [[ -v WINELOADER ]];
then
    abort "A WINE installation must be active before creating a prefix."
else
    if [[ -v WINE_PATH ]];
    then
        WINE_ARCH=$(cat "$WINE_PATH/.wine_arch")

        if [[ "$WINE_ARCH" == "i386" ]] && [[ "$PREFIX_ARCH" == "win64" ]] ||
           [[ "$WINE_ARCH" == "amd64" ]] && [[ "$PREFIX_ARCH" == "win32" ]];
        then
            echo -n "You are trying to create a '$PREFIX_ARCH' for a "
            echo "'$WINE_ARCH' WINE installation and both architectures must"
            echo "be the same."
            echo -n "You need a win32 prefix for a i386 WINE and a win64"
            echo "prefix for a amd64 WINE."
            echo ""

            abort
        fi
    else
        echo "Unable to check the active WINE installation architecture."
        echo ""
        echo "Keep in mind that you need to create a prefix that matches"
        echo "the current loaded WINE architecture."
        echo ""

        pause
    fi
fi


if [[ -v WIN_ROOT ]] && [[ -d "$WIN_ROOT" ]];
then
    echo "Using '$WIN_ROOT' as prefixes root."
    echo "Testing $WIN_ROOT for write permissions ..."

    touch "$WIN_ROOT/touched"

    if ! [[ "$?" == "0" ]];
    then
        echo -n "ERROR: Cannot write in '$WIN_ROOT'\n" && exit 1
    else
        rm "$WIN_ROOT/touched"
        echo "All seems OK."

        export WINEPREFIX="$WIN_ROOT/$PREFIX_NAME"
    fi
else
    if [[ "$PREFIX_NAME" == ".wine" ]] || [[ "$PREFIX_NAME" == ".wine64" ]];
    then
        export WINEPREFIX="$HOME/$PREFIX_NAME"
    else
        export WINEPREFIX="$HOME/.local/share/wineprefixes/$PREFIX_NAME"
    fi
fi


export WINEARCH=$PREFIX_ARCH


PREFIX_PATH=$(dirname "$WINEPREFIX")

if ! [[ -d "$PREFIX_PATH" ]];
then
    mkdir -p "$PREFIX_PATH"
fi


echo -n "Checking if a prefix named '$PREFIX_NAME'"
echo "already exists in '$PREFIX_PATH ..."


if [[ -d "$WINEPREFIX/dosdevices" ]];
then
    if [[ -d "$WINE_PREFIX/drive_c/Program Files (x86)" ]];
    then
        export WINEARCH="win64"
    else
        export WINEARCH="win32"
    fi

    if ! [[ -f "$WINEPREFIX/activate" ]];
    then
        echo "The prefix exists but no activator was found."
        echo "Both the activator and the defaulter will be created now."
        echo ""

        install_activator
        install_defaulter
    else
        echo "Both the prefix and the needed scripts are already present."
        echo "Nothing to do then."
        echo ""
    fi

else
    setup_prefix
fi
