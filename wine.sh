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


ask_yn()
{
    QUESTION=$1

    if ! [[ "$QUESTION" == "" ]];
    then
        read -p "$QUESTION (Y/n): " answer

        if [[ "$answer" == "Y" ]] || [[ "$answer" == "S" ]];
        then
            return 0
            
        elif [[ "$answer" == "n" ]];
        then
            return 1
            
        else
            return -1
        fi
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


filext()
{
    FULL_PATH=$1

    FILE_NAME=$(basename "$FULL_PATH")
    FILE_EXTENSION=${FILE_NAME##*.}

    echo .$FILE_EXTENSION
}


is_wine_installation()
{
	WINE_PATH="$1"

	if [[ -d "$WINE_PATH" ]];
	then
	    WINE_SERVER=$(find "$WINE_PATH"/** -type f -name "wineserver")

	    if ! [[ "$WINE_SERVER" == "" ]];
	    then
	        return 0
	    fi
	fi

	return 1
}


is_wine_prefix()
{
    PREFIX="$1"
    
	if [[ -d "$PREFIX" ]];
	then
        if [[ -d "$PREFIX/dosdevices" ]];
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

    if [[ "$WINE_BRANCH" == "" ]];
    then
        WINE_BRANCH="stable"
    fi

    if [[ "$WINE_VERSION" == "" ]];
    then
        WINE_VERSION="10.0.0.0"
    fi

    if ! [[ "$WINE_BRANCH" == "stable" ]] && 
       ! [[ "$WINE_BRANCH" == "staging" ]];
    then
        abort "WINE branch must be 'stable' or 'staging'."
    fi

	WINE_URL="https://dl.winehq.org/wine-builds/debian/pool/main/w"
	LATEST_DEBIAN="trixie"

	WINE_BASE="wine-${WINE_BRANCH}"
    WINE_BASE+="_${WINE_VERSION}"
    WINE_BASE+="~${LATEST_DEBIAN}-1_amd64.deb"

    WINE_i386="wine-${WINE_BRANCH}-i386"
    WINE_i386+="_${WINE_VERSION}"
    WINE_i386+="~${LATEST_DEBIAN}-1_i386.deb"

    WINE_amd64="wine-${WINE_BRANCH}-amd64"
    WINE_amd64+="_${WINE_VERSION}"
    WINE_amd64+="~${LATEST_DEBIAN}-1_amd64.deb"

    BASE_URL="$WINE_URL"
    
    if [[ "$WINE_BRANCH" == "staging" ]];
    then
        BASE_URL+="/wine-staging"
    else
        BASE_URL+="/wine"
    fi

    echo ""
    echo "Downloading WINE (Base) ($WINE_BRANCH) ($WINE_VERSION) ..."
    echo "----------------------------------------------------------"

    curl -LO "$BASE_URL/$WINE_BASE"

    if ! [[ "$?" == "0" ]];
    then
        abort "Failed."
    fi

    echo ""
    echo "Downloading WINE (32 bit) ($WINE_BRANCH) ($WINE_VERSION) ..."
    echo "------------------------------------------------------------"

    curl -LO "$BASE_URL/$WINE_i386"

    if ! [[ "$?" == "0" ]];
    then
        abort "Failed."
    fi

    echo ""
    echo "Downloading WINE (64 bit) ($WINE_BRANCH) ($WINE_VERSION) ..."
    echo "------------------------------------------------------------"

    curl -LO "$BASE_URL/$WINE_amd64"

    if ! [[ "$?" == "0" ]];
    then
        abort "Failed."
    fi

    if [[ -d "/tmp/wine" ]];
    then
        rm -r /tmp/wine
    fi
    
    mkdir -p /tmp/wine
    mv wine-*.deb /tmp/wine/
}


install_wine()
{
    PACKAGE="$1"
    INSTALL_PATH="$2"

    if [[ -d "$PACKAGE" ]];
    then
        ITEMS=$(ls "$PACKAGE"/*.deb)
        ITEMS=$(echo "$ITEMS" | grep -m 1 "wine")

        if [[ "$ITEMS" == "" ]];
        then
            echo -e "Given a path instead of a WINE package, but this place"
            echo -e "does not contain wine packages.\n"

            abort "Aborting installation."
        fi

        PACKAGE="$ITEMS"
    fi

    PACKAGE_NAME=$(basename "$PACKAGE")
    
    WINE_VERSION=$(echo "$PACKAGE_NAME" | grep -oP '\d+(?:\.\d+)+')
    WINE_PACKAGES_PATH=$(dirname "$PACKAGE")
    WINE_FOLDER="wine-$WINE_VERSION"
    WINE_TMP="wine-tmp"

    is_wine_installation "$INSTALL_PATH/$WINE_FOLDER"
    
    if [[ "$?" == "0" ]];
    then
        echo -n "A existing WINE installation was found in "
        echo -ne "'$INSTALL_PATH/$WINE_FOLDER'.\n"

        ask_yn "Overwrite it?"

        if [[ "$?" == "1" ]] || [[ "$?" == "-1" ]];
        then
            abort "Aborted."
        fi
    fi

    if ! [[ -d "$INSTALL_PATH/$WINE_FOLDER" ]];
    then
        mkdir -p "$INSTALL_PATH/$WINE_FOLDER"
    fi

    mkdir -p "$WINE_TMP/wine"

    echo -e ""
    echo -e "Extracting WINE packages to '$INSTALL_PATH'..."
    echo -e "----------------------------------------------"

    for p in $(ls "$WINE_PACKAGES_PATH/wine-"*.deb)
    do
        PACKAGE_FILENAME=$(basename "$p")
        
        echo " - Processing $PACKAGE_FILENAME ..."
        
        mkdir -p "$WINE_TMP/ar"
        
        ar x "$p" --output "$WINE_TMP/ar"
    
	    if [[ "$?" == "0" ]];
	    then
	        tar xf "$WINE_TMP/ar/data.tar.xz" -C "$WINE_TMP/wine"

	        if [[ "$?" == "0" ]];
	        then
	            if [[ -d "$WINE_TMP/wine/opt" ]];
	            then
	                cp -ru "$WINE_TMP/wine/opt" "$INSTALL_PATH/$WINE_FOLDER/"
	            fi

	            if [[ -d "$WINE_TMP/wine/usr" ]];
	            then
	                cp -ru "$WINE_TMP/wine/usr" "$INSTALL_PATH/$WINE_FOLDER/"
	            fi
	            
	            rm -r "$WINE_TMP/ar"
	        fi
	    fi
	done

	is_wine_installation "$INSTALL_PATH/$WINE_FOLDER"
	
    if [[ "$?" == "0" ]];
    then
        echo -e "All done.\n"
        rm -r "$WINE_TMP"
    else
        abort "Something failed. Cannot validate WINE installation."
    fi
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
	echo -e ": Downloads WINE to /tmp/wine folder."
	echo -e "  Default branch and version: stable 10.0.0.0"
	echo -e ""
	echo -e "wine.sh --install <WINE package> [install dir]"
	echo -e ": Installs a downloaded WINE version."
	echo -e "  If no install dir is given, ~/.local/bin/wine will be used."
	echo -e "  WINE package can be any of the two that gets downloaded."
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
            WINE_VERSION="$3"
        fi
    fi

    download_wine $WINE_BRANCH $WINE_VERSION

elif [[ "$1" == "--install" ]];
then
    if ! [[ "$2" == "" ]];
    then
        WINE_PACKAGE="$2"

        if [[ "$3" == "" ]];
        then
            WINE_INSTALL_PATH="$HOME/.local/bin/wine"
        else
            WINE_INSTALL_PATH="$3"
        fi

        install_wine "$WINE_PACKAGE" "$WINE_INSTALL_PATH"
    fi

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

is_wine_installation "$WINE_PATH"

if ! [[ "$?" == "0" ]];
then
    echo "If running without params, the script must be inside a valid"
    echo "WINE installation, because it will be used for executing"
    echo "Windows programs directly."

    abort
fi


if ! [[ "$1" == "" ]] && [[ -f "$1" ]];
then
    EXEC=$(realpath "$1")
    EXEC_FILENAME=$(basename "$EXEC")
    EXEC_FILENAME_WITHOUT_EXT=$(basename $(filext "$EXEC_FILENAME"))
    EXEC_WINECFG=".$(lowercase "$EXEC_FILENAME_WITHOUT_EXT")_winecfg"

    ARGS=${@:2}

    if [[ -f "$EXEC_WINECFG" ]];
    then
        source "$EXEC_WINECFG"
    fi

    if ! [[ "$WINEPREFIX" == "" ]];
    then
        load_prefix "$WINEPREFIX"
    else
        EXEC_TYPE=$(exec_type "$EXEC")

        if [[ "$EXEC_TYPE" == "windows-i386" ]];
        then
            PREFIX="$HOME/.wine"
           
        elif [[ "$EXEC_TYPE" == "windows-amd64" ]];
        then
            PREFIX="$HOME/.wine64"
        fi

        load_prefix "$PREFIX"
    fi

    load_wine "$WINE_PATH"
    
    wine "$EXEC" "$ARGS"
fi

