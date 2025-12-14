#!/bin/bash


abort()
{
    MESSAGE=$1

    if ! [[ "$MESSAGE" == "" ]];
    then
        echo "$MESSAGE"
        echo ""
    fi

    if [[ "${BASH_SOURCE}" == "" ]];
    then
        return 1
    else
        exit 1
    fi
}


exec_type()
{
    EXEC=$1
    FILE_TYPE=$(file -L "$EXEC")

    echo ${FILE_TYPE} | grep "ELF 32-bit" > /dev/null

    if [[ "$?" == "0" ]];
    then
        echo "linux-i386"
        echo ""
    else
        echo ${FILE_TYPE} | grep "ELF 64-bit" > /dev/null

        if [[ "$?" == "0" ]];
        then
            echo "linux-amd64"
            echo ""
        else
            echo ${FILE_TYPE} | grep "PE32 executable" > /dev/null

            if [[ "$?" == "0" ]];
            then
                echo "windows-i386"
                echo ""
            else
                echo ${FILE_TYPE} | grep "PE32+ executable" > /dev/null

                if [[ "$?" == "0" ]];
                then
                    echo "windows-amd64"
                    echo ""
                fi
            fi
        fi
    fi
}


install_prefix_activator()
{
    if ! [[ -f "$WINE_PATH/for_prefixes/.activate_prefix" ]];
    then
        echo "Cannot create activator for prefix '$WINEPREFIX'."
        abort "Template not found."
    fi

    ACTIVATOR=$WINEPREFIX/activate

    cp "$WINE_PATH/for_prefixes/.activate_prefix" "$ACTIVATOR"

    sed -i "s|WINEPREFIX_PLACEHOLDER|$WINEPREFIX|g" "$ACTIVATOR"
    sed -i "s|WINEARCH_PLACEHOLDER|$WINEARCH|g" "$ACTIVATOR"

    chmod +x "$ACTIVATOR"
    
    echo "Activator installed for prefix '$WINEPREFIX'."
    echo "Execute '. $WINEPREFIX/activate' for activate this prefix."
    echo ""
}


install_prefix_defaulter()
{
    if ! [[ -f "$WINE_PATH/for_prefixes/.make_prefix_default" ]];
    then
        echo "Cannot create defaulter for prefix '$WINEPREFIX'."
        abort "Template not found."
    fi

    DEFAULTER="$WINEPREFIX/make_default"

    cp "$WINE_PATH/for_prefixes/.make_prefix_default" "$DEFAULTER"
    chmod +x "$DEFAULTER"

    echo "Execute '$WINEPREFIX/make_default' for set this prefix as the"
    echo "default one for running apps with win_start script."
    echo ""
}


filext()
{
    FULL_PATH=$1

    FILE_NAME=$(basename "$FULL_PATH")
    FILE_EXTENSION=${FILE_NAME##*.}

    echo .$FILE_EXTENSION
}


load_prefix()
{
    EXEC_TYPE="$1"

    if [[ "$EXEC_TYPE" == "windows-i386" ]];
    then
        if ! [[ -d "$HOME/.wine" ]];
        then
            setup_prefix "$WINE_PREFIXES/wine32" win32
        fi

        source "$HOME/.wine/activate"
        
    elif [[ "$EXEC_TYPE" == "windows-amd64" ]];
    then
        if ! [[ -d "$HOME/.wine64" ]];
        then
            setup_prefix "$WINE_PREFIXES/wine64" win64
        fi

        source "$HOME/.wine64/activate"
    else
        abort "The specified executable isn't a Windows 32/64 bit one."
    fi
}


load_wine()
{
    WINE_PATH="$1"
    
   	WINESERVER=$(find "$WINE_PATH"/** -type f -name "wineserver")
   
   	if [[ "$WINESERVER" == "" ]];
   	then
        abort "No WINE installation found at '$WINE_PATH'."
   	fi

	if ! [[ -v WINEARCH ]];
	then
        abort "No WINE prefix loaded. Unable to check the required arch."
	fi

	export WINE_BINARIES=$(find "$WINE_PATH"/** -type d -name "bin")
    export WINE_ROOT=$(dirname "$WINE_BINARIES")

    if [[ "$WINEARCH" == "win32" ]];
    then
        export WINELOADER="$WINE_BINARIES/wine"
        export WINEDLLPATH="$WINE_ROOT/lib/wine"

        export WINE32_UTILS="$WINE_UTILS/lib/wine/i386-windows"
        export WINE_UTILS="$WINE32_UTILS"
    else
        export WINELOADER="$WINE_BINARIES/wine64"
        export WINEDLLPATH="$WINE_DLL_PATH/lib64/wine"

        export WINE64_UTILS="$WINE_UTILS/lib64/wine/x86_64-windows"
        export WINE_UTILS="$WINE64_UTILS"
    fi

    export WINE="$WINELOADER"
    export WINESERVER="$WINE_BINARIES/wineserver"
}


setup_prefix()
{
    export WINEPREFIX="$1"
    export WINEARCH="$2"
    
    echo "Initializing $WINEARCH prefix '$WINEPREFIX' ..."
    echo ""

    "$WINELOADER" "$WINE_UTILS/wineboot.exe"

    if ! [[ "$?" == "0" ]];
    then
        echo -e "Initialization failed. Maybe a permissions problem.\n"
        exit 1
    fi

    echo "Prefix created. The helper scripts will be added now."
    echo ""

    echo "$WINEARCH" > "$WINEPREFIX/.arch"

    install_prefix_activator
    install_prefix_defaulter

    cp -u "$WINE_PATH/for_prefixes/enable_dx11_support.sh" "$WINEPREFIX/"
    cp -u "$WINE_PATH/for_prefixes/enable_dx12_support.sh" "$WINEPREFIX/"

    if [[ "$WINEARCH" == "win32" ]] && ! [[ -d "$HOME/.wine" ]];
    then
        "$WINEPREFIX/make_default"
        
    elif [[ "$WINEARCH" == "win64" ]] && ! [[ -d "$HOME/.wine64" ]];
    then
        "$WINEPREFIX/make_default"
    fi
}


usage()
{
	echo -e "wine.sh <executable> [args]"
	echo -e ": Executes a program with the default prefix."
	echo -e ""
	echo -e "wine.sh --setup_prefix <prefix name> [win32|win64]"
	echo -e ": Create a new prefix in ~/.local/share/wineprefixes."
	echo -e "  The default architecture, if none is specified, is win64."
	echo -e ""
	echo -e "wine.sh --load_prefix <prefix name>"
	echo -e ": Use with 'source' or '.'."
	echo -e "  Loads the given prefix in the current environment."
	echo -e ""
	echo -e "wine.sh --use <WINE installation"
	echo -e ": Use with 'source' or '.'."
	echo -e "  Activates the given WINE installation."
	echo -e ""
	echo -e "wine.sh --download [branch] [version]"
	echo -e ": Downloads WINE to ~/.local/bin/wine folder."
	echo -e "  Default branch and version: stable 10.0.0.0"
	echo -e ""
	echo -e "wine.sh --autoload <WINE installation>"
	echo -e "wine.sh --autoload_prefix <prefix name>"
	echo -e ""
}




if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    abort
fi


export WINE_PATH=$(realpath $(dirname "$0"))
export WINE_PREFIXES="$HOME/.local/share/wineprefixes"


if ! [[ "$WINESERVER" == "" ]];
then
    export WINE_BINARIES=$(dirname "$WINESERVER")
    
    if ! [[ "$1" == "" ]] && [[ -f "$1" ]];
    then
        EXEC=$(realpath "$1")
        EXEC_FILENAME=$(basename "$EXEC")
        EXEC_FILENAME_WITHOUT_EXT=$(basename $(filext "$EXEC_FILENAME"))
    
        EXEC_WINECFG=".$(lowercase "$EXEC_FILENAME_WITHOUT_EXT")_winecfg"

        EXEC_TYPE=$(exec_type "$EXEC")

        load_prefix $EXEC_TYPE
    fi
fi
