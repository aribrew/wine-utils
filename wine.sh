#!/bin/bash


ACTIVATOR="#!/bin/bash"
ACTIVATOR+=""
ACTIVATOR+="export WINEPREFIX=WINEPREFIX_PLACEHOLDER"
ACTIVATOR+="export WINEARCH=WINEARCH_PLACEHOLDER"
ACTIVATOR+="export WIN_C=WINEPREFIX_PLACEHOLDER/drive_c"
ACTIVATOR+="export WIN_D=WINEPREFIX_PLACEHOLDER/drive_d"
ACTIVATOR+=""
ACTIVATOR+=""
ACTIVATOR+="echo \"WINE prefix '$WINEPREFIX' activated.\""
ACTIVATOR+="echo \"Unset WINEDEBUG var to view errors and warnings.\""
ACTIVATOR+="echo \"\""


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


is_wine_installation()
{
	WINE_PATH="$1"

	if [[ -d "$WINE_PATH" ]];
	then
	    WINESERVER=$(find "$WINE_PATH"/** -type f -name "wineserver")

	    if [[ "$WINESERVER" == "" ]];
	    then
	        return 1
	    fi

	    return 0
	fi
}


is_wine_prefix()
{
	if [[ -d "$1" ]];
	then
	    WINEPREFIX="$1"
	    
        if [[ -d "$WINEPREFIX/dosdevices" ]];
        then
            return 0
        fi
	fi

	return 1
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
    if [[ -d "$1" ]];
    then
        echo "TODO"
    fi
}


load_required_prefix()
{
    EXEC_TYPE="$1"

    if [[ "$EXEC_TYPE" == "windows-i386" ]];
    then
        if [[ -d "$HOME/.wine" ]];
        then
            source "$HOME/.wine/activate"
        else
            abort "No default 32 bit prefix found."
        fi
        
    elif [[ "$EXEC_TYPE" == "windows-amd64" ]];
    then
        if [[ -d "$HOME/.wine64" ]];
        then
            source "$HOME/.wine64/activate"
        else
            abort "No default 64 bit prefix found."
        fi
        
    else
        abort "The specified executable isn't a Windows one."
    fi
}


load_wine()
{
    WINE_PATH="$1"

    is_wine_installation "$WINE_PATH"
    
   	if ! [[ "$?" == "0" ]];
   	then
        abort "No WINE installation found at '$WINE_PATH'."
   	fi

	if ! [[ -v WINEARCH ]];
	then
        abort "No WINE prefix loaded. Load one first."
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

    echo "Activated Wine $WINE_BRANCH $WINE_VERSION: $WINE_PATH"
    echo ""
    echo "You have available the following aliases: "
    echo "- wine: Default WINE executable for the loaded prefix"
    echo "- wine32: WINE executable for 32 bit software"
    echo "- wine64: WINE executable for 64 bit software"
    echo "- wineboot: Performs a 'reboot' of the loaded prefix."
    echo "- explorer, reg, regedit: Launch these Windows programs." 
    echo ""
}


set_default_wine()
{
    WINE_PATH="$1"
    
	echo "$WINE_PATH" > "$HOME/.default_wine"
	            
	echo -e "WINE installation at '$WINE_PATH' made the default one."
	echo -e "It will be loaded for preparing new prefixes.\n"
	echo ""
}


setup_prefix()
{
    export WINEPREFIX="$1"
    export WINEARCH="$2"

    if ! [[ -v WINELOADER ]];
    then
        if ! [[ -f "$HOME/.default_wine" ]];
        then
            abort "No WINE installation defined as the default."
        else
            WINE_PATH=$(cat "$HOME/.default_wine")

            load_wine "$WINE_PATH"
        fi
    fi
    
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
    echo -e "wine.sh --set_default <WINE installation>"
    echo -e ": Set this WINE installation as the default one."
    echo -e "  This is required by 'setup_prefix' to preload it."
    echo -e ""
	echo -e "wine.sh --setup_prefix <prefix name> [win32|win64]"
	echo -e ": Create a new prefix in ~/.local/share/wineprefixes."
	echo -e "  The default architecture, if none is specified, is win64."
	echo -e ""
    echo -e "wine.sh --load <WINE installation"
    echo -e ": Use with 'source' or '.'."
    echo -e "  Activates the given WINE installation."
    echo -e ""
	echo -e "wine.sh --load_prefix <prefix name>"
	echo -e ": Use with 'source' or '.'."
	echo -e "  Loads the given prefix in the current environment."
	echo -e ""
	echo -e "wine.sh --download [branch] [version]"
	echo -e ": Downloads WINE to ~/.local/bin/wine folder."
	echo -e "  Default branch and version: stable 10.0.0.0"
	echo -e ""
	echo -e "wine.sh --autoload <WINE installation>"
	echo -e "wine.sh --autoload_prefix <prefix name>"
	echo -e ""
}




export WINE_PREFIXES="$HOME/.local/share/wineprefixes"


if [[ "$1" == "" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    abort
fi


if [[ "$1" == "--set_default" ]];
then
    if ! [[ "$2" == "" ]];
    then
        WINE_PATH="$2"

        is_wine_installation "$WINE_PATH"

        if [[ "$?" == "0" ]];
        then
            set_default_wine "$WINE_PATH"
        fi
    fi
    
elif [[ "$1" == "--setup_prefix" ]];
then
    echo "TODO"    

elif [[ "$1" == "--load" ]];
then
    if ! [[ "$2" == "" ]];
    then
        WINE_PATH="$2"
        
        is_wine_installation "$WINE_PATH"
        
        if [[ "$?" == "0" ]];
        then
            load_wine "$WINE_PATH"
        fi
    fi
    
elif [[ "$1" == "--load_prefix" ]];
then
    if ! [[ "$2" == "" ]];
    then
        WINEPREFIX="$2"

        is_wine_prefix "$WINEPREFIX"

        if [[ "$?" == "0" ]];
        then
            load_prefix "$WINEPREFIX"
        fi
    fi

elif [[ "$1" == "--download" ]];
then
    echo "TODO"

elif [[ "$1" == "--autoload" ]];
then
    echo "TODO"

elif [[ "$1" == "--autoload_prefix" ]];
then
    echo "TODO"
else
    echo "TODO"
fi


export WINE_PATH=$(realpath $(dirname "$0"))


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
