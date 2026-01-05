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


are_same()
{
	FIRST_FILE="$1"
	SECOND_FILE="$2"

	if [[ "$FIRST_FILE" == "" ]] || [[ "$SECOND_FILE" == "" ]];
	then
        return -1
        
	elif ! [[ -f "$FIRST_FILE" ]] || ! [[ -f "$SECOND_FILE" ]];
	then
	    return -1
	else
        FIRST_MD5=$(md5sum "$FIRST_FILE" | cut -d ' ' -f 1)
        SECOND_MD5=$(md5sum "$SECOND_FILE" | cut -d ' ' -f 1)

        if [[ "$FIRST_MD5" == "$SECOND_MD5" ]];
        then
            return 0;
        else
            return 1;
        fi
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


check_script()
{
	SCRIPT=$(realpath $0)

	bash -n "$SCRIPT"
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


find_wine_installations()
{
	SEARCH_PATH="$1"

	WINE_SERVERS=$(find "$SEARCH_PATH"/** -type f -name "wineserver")

	echo "$WINE_SERVERS"
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


extract_wine()
{
    PACKAGE="$1"
    INSTALL_PATH="$2"

    if [[ "$INSTALL_PATH" == "" ]];
    then
        if [[ -v WINE_ENV ]];
        then
            INSTALL_PATH="$WINE_ENV"
        else
            INSTALL_PATH="$HOME/.local/bin/wine"
        fi
    fi

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
        echo "$WINE_VERSION" > "$INSTALL_PATH/$WINE_FOLDER/.wine_version"
        echo "$WINE_BRANCH" > "$INSTALL_PATH/$WINE_FOLDER/.wine_branch"
        
        echo -e "All done.\n"

        rm -r "$WINE_TMP"
    else
        abort "Something failed. Cannot validate WINE installation."
    fi
}


install_script()
{
    local SCRIPT=$(realpath "$0")
    local SCRIPT_FILE=$(basename "$SCRIPT")
    
    local INSTALL_PATH="$HOME/.local/bin"
    
	if ! [[ -d "$INSTALL_PATH" ]];
	then
        mkdir -p "$INSTALL_PATH"
	fi

	if [[ -f "$INSTALL_PATH/$SCRIPT_FILE" ]];
	then
	    are_same "$INSTALL_PATH/$SCRIPT_FILE" "$SCRIPT"
	
	    if [[ "$?" == "1" ]];
	    then
	        cp -u "$SCRIPT" "$INSTALL_PATH/$SCRIPT_FILE"
	        echo -e "Your wine.sh has been updated.\n"
	    fi
	else
	    cp "$SCRIPT" "$INSTALL_PATH/$SCRIPT_FILE"
	    echo -e "Wine.sh has been installed in ~/.local/bin.\n"
	fi
}


install_wine_deps()
{
    if [[ -f "/usr/local/share/.wine_deps_installed" ]];
    then
        echo -e "\nDependencies for WINE already installed.\n"
    else
        echo -e "Now WINE will be installed for easy dependency installation."
        echo -e "After complete, WINE packages will be removed."
        echo -e "================================================="

        install_wine_repo

        if ! [[ "$?" == "0" ]];
        then
            abort "Failed installing WINE repository. Cannot continue."
        fi
        
	    if ! [[ "$(which apt)" == "" ]];
	    then
	        PACKAGES="wine-stable wine-stable-amd64 wine-stable-i386"
	        
	        if ! [[ "/etc/apt/keyrings/winehq-archive.key" ]];
	        then
	            sudo apt install --install-recommends -y $PACKAGES
	            
                if ! [[ "$?" == "0" ]];
                then
                    abort "Failed!"
                fi

                sudo apt remove $PACKAGES -y
                
                sudo touch "/usr/local/share/.wine_deps_installed"
	        fi
	        
	    elif ! [[ "$(which dnf)" == "" ]];
	    then
            sudo dnf install wine-stable -y

            if ! [[ "$?" == "0" ]];
            then
                abort "Failed!"
            fi

            sudo dnf remove wine-stable --noautoremove -y

            sudo touch "/usr/local/share/.wine_deps_installed"
	    fi
	fi
}


install_wine_repo()
{
	OS_NAME=$(os_name)
	OS_VERSION=$(os_version)

	if ! [[ "$(which apt)" == "" ]];
	then
	    if [[ -f "$APT_SOURCES_DIR/winehq-${OS_VERSION}.sources" ]] &&
	       [[ -f "$APT_KEYRINGS_DIR/winehq-archive.key" ]]; 
   		then
            echo -e "WINE repository already installed."
        else
	        APT_SOURCES_DIR="/etc/apt/sources.list.d"
		    APT_KEYRINGS_DIR="/etc/apt/keyrings"
		
		    WINE_APT_URL="https://dl.winehq.org/wine-builds/${OS_NAME}"
		    WINE_APT_URL+="/dists/${OS_VERSION}"
		    WINE_APT_URL+="/winehq-${OS_VERSION}.sources"
		
		    WINE_GPG_URL="https://dl.winehq.org/wine-builds/winehq.key"
		
		    if ! [[ -d "$APT_KEYRINGS_DIR" ]]; 
		    then
		        sudo mkdir -p "$APT_KEYRINGS_DIR"
		    fi

		    if ! [[ -f "$APT_SOURCES_DIR/winehq-${OS_VERSION}.sources" ]] ||
		       ! [[ -f "$APT_KEYRINGS_DIR/winehq-archive.key" ]]; 
		    then
		        echo ""
		        echo "-e Enabling i386 repository if not available yet ...\n"
		
		        sudo dpkg --add-architecture i386
		
		        sudo apt update
		
		        if [[ "$(which wget)" == "" ]];
		        then
		            echo -e "\nInstalling wget ..."
		            echo -e "---------------------"
		        
		            sudo apt install -y wget
		
		            if ! [[ "$?" == "0" ]];
		            then
		                abort "Failed!"
		            fi
		        fi
		
		        SOURCES_LIST="/etc/apt/sources.list"
		    
		
		        echo ""
		        echo "Downloading WINE GPG key and sources.list for APT..."
		        echo "----------------------------------------------------"
		        echo ""
		
		        wget -N $WINE_GPG_URL
		
		        if ! [[ "$?" == "0" ]]; 
		        then
		            abort "Failed downloading GPG key."
		        fi
		
		
		        wget -N $WINE_APT_URL
		
		        if ! [[ "$?" == "0" ]]; 
		        then
		            abort "Failed downloading APT sources list."
		        fi
		
		
		        sudo mv winehq.key "$APT_KEYRINGS_DIR/winehq-archive.key"
		        sudo mv winehq-${OS_VERSION}.sources "$APT_SOURCES_DIR/"
		
		
		        echo "Refreshing APT database ..."
		        echo ""
		
		        sudo apt update
		
		        if ! [[ "$?" == "0" ]]; 
		        then
		            abort "Something is wrong :S"
		        fi
		    fi
        fi
		
	elif ! [[ "$(which dnf)" == "" ]];
	then
        sudo dnf repolist | grep -q WineHQ

        if [[ "$?" == "0" ]];
        then
            echo -e "WINE repository already installed.\n"
        else
	        FEDORA_VERSION=$(cat /etc/os_release | grep VERSION_ID)
	        FEDORA_VERSION=$(echo "$FEDORA_VERSION" | cut -d '=' -f 2)

	        if [[ "$FEDORA_VERSION" == "" ]];
	        then
	            abort "Unable check Fedora version."
	        fi
	        
	        REPO_URL="https://dl.winehq.org/wine-builds/fedora/$FEDORA_VERSION"
	        REPO_URL+="/winehq.repo"
	        
	        dnf5 config-manager addrepo --from-repofile="$REPO_URL"

	        if ! [[ "$?" == "0" ]];
	        then
                abort "Failed installing the WINE repository."
	        fi
        fi
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


os_name()
{
    echo "$(cat /etc/os-release | grep '^ID=' | cut -d '=' -f 2)"
}


os_version()
{
    if [[ "$(os_name)" == "manjaro" ]];
    then
        echo "rolling"
    else
        OS_INFO=$(cat /etc/os-release)
        OS_VERSION=$(echo "$OS_INFO" | grep '^VERSION_CODENAME=')
        
        echo "$OS_VERSION" | cut -d '=' -f 2 
    fi
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

    if [[ "$PREFIX/drive_c/Program Files (x86)" ]];
    then
        echo -e "Not a 32 bit prefix.\n"
    else
	    ln -sf "$PREFIX" "$HOME/.wine"
	    echo -e "Prefix '$PREFIX' is now the default for 32 bit.\n"
	fi
}


set_default_win64_prefix()
{
	PREFIX="$1"

	is_wine_prefix "$PREFIX"

	if ! [[ "$?" == "0" ]];
	then
	    abort "Invalid prefix '$PREFIX'."
	fi

	if [[ "$PREFIX/drive_c/Program Files (x86)" ]];
	then
    	ln -sf "$PREFIX" "$HOME/.wine64"
    	echo -e "Prefix '$PREFIX' is now the default for 64 bit.\n"
	else
        echo -e "Not a 64 bit prefix.\n"
	fi
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

    PREFIX_PATH=$(dirname "$WINEPREFIX")
    
    if ! [[ -d "$PREFIX_PATH" ]];
    then
        make -p "$PREFIX_PATH"
    fi

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
	echo -e "  If a file {executable}_winecfg is found, and contains"
	echo -e "  variables such as WINEPREFIX, this configuration will be"
	echo -e "  used instead the default one."
	echo -e ""
	echo -e "  Same if you export a WINEPREFIX variable manually."
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
	echo -e "wine.sh --install <WINE path> [install dir]"
	echo -e ": Installs a downloaded WINE version."
	echo -e "  If no install dir is given, ~/.local/bin/wine will be used."
	echo -e ""
}




if [[ "$1" == "" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    abort
fi


install_script


export WINE_PREFIXES="$HOME/.local/share/wineprefixes"


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

    exit $?

elif [[ "$1" == "--set_default_win32_prefix" ]];
then
    if ! [[ "$2" == "" ]]
    then
        set_default_win32_prefix "$2"
    fi

    exit $?
    
elif [[ "$1" == "--set_default_win64_prefix" ]];
then
    if ! [[ "$2" == "" ]]
    then
        set_default_win64_prefix "$2"
    fi

    exit $?
    
elif [[ "$1" == "--setup_prefix" ]];
then
    if ! [[ "$2" == "" ]];
    then
        if [[ "$2" == "win32" ]];
        then
            setup_prefix "$WINE_PREFIXES/.wine" win32
            
        elif [[ "$2" == "win64" ]];
        then
            setup_prefix "$WINE_PREFIXES/.wine64" win64
        else
            if [[ "$3" == "win32" ]] || [[ "$3" == "win64" ]];
            then
                if [[ "$2" =~ "/" ]];
                then
                    setup_prefix "$2" $3
                else
                    setup_prefix "$WINE_PREFIXES/$2" $3
                fi
            fi
        fi
    fi

    exit $?

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

    exit $?
    
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

    exit $?

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

    if [[ -d "/tmp/wine" ]];
    then
        extract_wine "/tmp/wine" "/tmp/wine"
    fi

    exit $?

elif [[ "$1" == "--install" ]];
then
    if ! [[ "$2" == "" ]];
    then
        WINE_INSTALLATION="$2"

        if [[ "$3" == "" ]];
        then
            WINE_INSTALL_PATH="$HOME/.local/bin/wine"
        else
            WINE_INSTALL_PATH="$3"
        fi

        mv "$WINE_INSTALLATION" "$WINE_INSTALL_PATH"
    fi

    exit $?
fi


if ! [[ -v WINE_PATH ]];
then
    SCRIPT_PATH=$(realpath $(dirname "$0"))

    is_wine_installation "$SCRIPT_PATH"

    if [[ "$?" == "0" ]];
    then
        export WINE_PATH="$SCRIPT_PATH"

        echo -e "The script is being executed inside a WINE installation.\n"
        
        echo -e "Due WINE_PATH wasn't previously set, the script will use"
        echo -e "the current path as the default WINE installation."
    else
        if [[ -d "$HOME/.local/bin/wine" ]];
        then
            find_wine_installations "$HOME/.local/bin/wine"
        fi
    fi
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

    if ! [[ -v WINEPREFIX ]];
    then
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

    if ! [[ -v WINELOADER ]];
    then
        load_wine "$WINE_PATH"
    fi
    
    wine "$EXEC" "$ARGS"
fi

