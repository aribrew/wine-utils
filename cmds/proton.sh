#!/bin/bash


BASH_HELPERS="/opt/bin/bash_helpers"

if ! [ -f "$BASH_HELPERS" ];
then
    echo "Cannot find '$BASH_HELPERS'."
    echo ""

    exit 1
    
else
    source "$BASH_HELPERS"
fi


proton_usage()
{
    echo "Proton verbs:"
    echo "- run: Executes a program and terminates."
    echo "- waitforexitandrun: Same but without terminating the script"
    echo "- runinprefix: Run a program inside a certain prefix"
    echo "- destroyprefix: Deletes a prefix"
    echo "- getcompatpath"
    echo "- getnativepath"
    echo ""
}


usage()
{
    echo "Usage: proton.sh [path to game executable]"
    echo "       proton.sh [whatever you want]"
    echo "       proton.sh [-h|--help]"
    echo "       proton.sh --phelp"
    echo ""
    echo "Options -h and --help prints this help."
    echo "Option --phelp prints help relative to Proton itself."
    echo ""
    echo "If want to use a custom WINE prefix, set the WINEPREFIX"
    echo "environment variable previously."
    echo ""
    echo "Also, if WINECFG=1 is set, the WINE configurator will be launched."
    echo ""
    echo "By default, Proton 10.0 will be used, but you can set other if you"
    echo "want setting PROTON_VERSION variable. This must be the Proton"
    echo "folder name you want use."
    echo ""
    echo "Example: PROTON_VERSION=\"Proton 10.0\" proton.sh game.exe"
    echo ""
}


if [ "$1" == "-h" ] || [ "$1" == "--help" ];
then
    usage
    abort
fi




### Proton environment setup  ###
DEFAULT_PROTON="Proton 10.0"
STEAM_DIR="$HOME/.local/share/Steam"
export STEAM_COMPAT_CLIENT_INSTALL_PATH=$STEAM_DIR

if ! [ -v PROTON_VERSION ];
then
    PROTON_DIR="$STEAM_DIR/steamapps/common/$DEFAULT_PROTON"
else
    PROTON_DIR="$STEAM_DIR/steamapps/common/$PROTON_VERSION"
fi

PROTON="$PROTON_DIR/proton"

if ! [ -f "$PROTON" ];
then
    abort "Cannot find '$PROTON_VERSION'"
fi

if [ -v WINEPREFIX ];
then
    export STEAM_COMPAT_DATA_PATH="$WINEPREFIX"
else
    export STEAM_COMPAT_DATA_PATH="$STEAM_DIR/prefixes"
fi

if [ -v WINEARCH ];
then
    if [ "$WINEARCH" == "win32" ];
    then
        WINE_UTILS="$PROTON_DIR/files/lib/wine/i386-windows"

    elif [ "$WINEARCH" == "win64" ];
    then
        WINE_UTILS="$PROTON_DIR/files/lib/wine/x86_64-windows"
    else
        echo "Invalid WINEARCH config: $WINEARCH"
        echo "Setting to win64"

        export WINEARCH=win64
    fi
fi

#################################


if [ -f "$1" ];
then
    EXEC="$1"
    ARGS="${@:2}"

elif [ "$1" == "winecfg" ];
then
    EXEC="$WINE_UTILS/winecfg.exe"
fi


if ! [ -v WINEPREFIX ];
then
    EXEC_ARCH=$(exec_type "$EXEC")

    if [[ $EXEC_ARCH == *-i386 ]];
    then
        export STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA_PATH/win32"
    else
        export STEAM_COMPAT_DATA_PATH="$STEAM_COMPAT_DATA_PATH/win64"
    fi
fi


if ! [ -d "$STEAM_COMPAT_DATA_PATH" ];
then
    mkdir -p "$STEAM_COMPAT_DATA_PATH"
fi


if [ -v EXEC ];
then
    echo "DEBUG: $PROTON run \"$EXEC\""

    if [ "$ARGS" == "" ];
    then
        echo "Launching '$(basename \"$EXEC\")' ..."
        echo ""
    else
        echo "Launching '$(basename \"$EXEC\")' with '$ARGS' ..."
        echo ""
    fi


    "$PROTON" run "$EXEC" $ARGS

else
    if [ "$1" == "--phelp" ];
    then
        proton_usage
        abort
    else
        "$PROTON" $*
    fi
fi
