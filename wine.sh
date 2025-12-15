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


download_wine()
{
    WINE_BRANCH="$1"
    WINE_VERSION="$2"

    if ! [[ "$WINE_BRANCH" == "stable" ]] && 
       ! [[ "$WINE_BRANCH" == "staging"]];
    then
        abort "WINE branch must be 'stable' or 'staging'."
    fi

    WINE_BRANCH="($WINE_BRANCH)"
    WINE_VERSION="$(WINE_VERSION)"
    
	WINE_URL="https://dl.winehq.org/wine-builds/debian/pool/main/w"
	LATEST_DEBIAN="trixie"

	WINE_BASE="wine-${WINE_BRANCH}"
    WINE_BASE+="_${WINE_VERSION}"
    WINE_BASE+="~${LATEST_DEBIAN}-1_amd64.deb"

    WINE_i386="wine-${WINE_BRANCH}-i386"
    WINE_i386+="_${WINE_VERSION}"
    WINE_i386+="~${LATEST_DEBIAN}-1_i386.deb"

    BASE_URL="$WINE_URL"
    
    if [[ "$WINE_BRANCH" == "staging" ]];
    then
        BASE_URL+="/wine-staging"
    else
        BASE_URL+="/wine"
    fi

    echo ""
    echo "Downloading WINE (32 bit) $WINE_BRANCH $WINE_VERSION ..."
    echo "-------------------------------------------------------------"

    curl -LO "$BASE_URL/$WINE_BASE"

    if ! [[ "$?" == "0" ]];
    then
        abort "Failed downloading base WINE package."
    fi

    echo ""
    echo "Downloading WINE (64 bit) $WINE_BRANCH $WINE_VERSION ..."
    echo "-------------------------------------------------------------"

    curl -LO "$BASE_URL/$WINE_i386"

    if ! [[ "$?" == "0" ]];
    then
        abort "Failed downloading arch-specific WINE package."
    fi

    mkdir -p /tmp/wine-tmp
    mv wine-*.deb /tmp/wine-tmp/
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
        is_wine_prefix "$1"

        if [[ "$?" == "0" ]];
        then
            PREFIX="$1"
        fi
    else
        is_wine_prefix "$WINE_PREFIXES/$1"

        if [[ "$?" == "0" ]];
        then
            PREFIX="$WINE_PREFIXES/$1"
        fi

        if [[ "$PREFIX" == "" ]];
        then
            abort "Invalid prefix '$1'"
        else
            PREFIX_ARCH=$(prefix_arch "$PREFIX")
        
            export WINEPREFIX="$PREFIX"
            export WINEARCH="$PREFIX_ARCH"
            export WIN_C="$WINEPREFIX/drive_c"
            export WIN_D="$WINEPREFIX/drive_d"
            
            echo -e "WINE prefix '$WINEPREFIX' activated.\n"
        fi
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


prefix_arch()
{
	PREFIX="$1"

	is_wine_prefix "$PREFIX"

	if ! [[ "$?" == "0" ]];
	then
        abort "Can't check the architecture of the invalid prefix '$PREFIX'."
	fi

	if [[ -d "$PREFIX/drive_c/Program Files (x86)" ]];
    then
        export WINEARCH="win64"
    else
        export WINEARCH="win32"
    fi
}


set_default_win32_prefix()
{
	PREFIX="$1"

	is_wine_prefix "$PREFIX"

	if ! [[ "$?" == "0" ]];
	then
	    abort "Invalid prefix '$PREFIX'."
	fi

	ln -sf "$PREFIX" "$HOME/.wine"

	echo -e "Prefix '$PREFIX' is now the default for 32 bit.\n"
}


set_default_win64_prefix()
{
	PREFIX="$1"

	is_wine_prefix "$PREFIX"

	if ! [[ "$?" == "0" ]];
	then
	    abort "Invalid prefix '$PREFIX'."
	fi

	ln -sf "$PREFIX" "$HOME/.wine64"

	echo -e "Prefix '$PREFIX' is now the default for 64 bit.\n"
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

    cp -u "$WINE_PATH/for_prefixes/enable_dx11_support.sh" "$WINEPREFIX/"
    cp -u "$WINE_PATH/for_prefixes/enable_dx12_support.sh" "$WINEPREFIX/"

    if [[ "$WINEARCH" == "win32" ]] && ! [[ -d "$HOME/.wine" ]];
    then
        set_default_win32_prefix "$WINEPREFIX"
        
    elif [[ "$WINEARCH" == "win64" ]] && ! [[ -d "$HOME/.wine64" ]];
    then
        set_default_win64_prefix "$WINEPREFIX"
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
    echo -e "wine.sh --set_default_win32_prefix <prefix name>"
    echo -e "wine.sh --set_default_win64_prefix <prefix name>"
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

elif [[ "$1" == "--set_default_win32_prefix" ]];
then
    echo "TODO"

elif [[ "$1" == "--set_default_win64_prefix" ]];
then
    echo "TODO"
    
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
    if ! [[ "$2" == "" ]];
    then
        WINE_BRANCH="$2"

        if ! [[ "$3" == "" ]];
        then
            WINE_VERSION="3"
        fi
    fi

    download_wine $WINE_BRANCH $WINE_VERSION

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
