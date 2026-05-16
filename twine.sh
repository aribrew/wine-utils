#!/bin/bash

abort()
{
    local MESSAGE=$1

    if ! [[ "$MESSAGE" == "" ]];
    then
        echo "$MESSAGE"
        echo ""
    fi

    if [[ "$0" == *bash ]] || [[ "$0" == *zsh ]];
    then
        return 1
    else
        exit 1
    fi
}


ask_yn()
{
    local QUESTION=$1

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
    local SCRIPT=$(realpath $0)

    bash -n "$SCRIPT"
}


disable_virtual_desktop()
{
    if [[ -v WINELOADER ]];
    then
        if ! [[ -v WINEPREFIX ]];
        then
            if ! [[ "$1" == "" ]];
            then
                WINEPREFIX="$1"
            fi
        fi

        is_wine_prefix "$WINEPREFIX"

        if [[ "$?" == "0" ]];
        then
            load_prefix "$WINEPREFIX"
            
            echo -e "Disabling WINE Virtual Desktop..."
            
            WINE_CMDLINE="reg delete "
            WINE_CMDLINE+="\"HKCU\Software\Wine\Explorer\" "
            WINE_CMDLINE+="/v Desktop /f"

            wine $WINE_CMDLINE
        fi
    fi
}


enable_dx11()
{
    local WINEPREFIX="$1"

    if ! [[ -f "$PREFIX/opt/bin/winetricks" ]];
    then
        abort "Winetricks not found."
    fi

    echo ""
    echo "Installing DXVK (DirectX -> Vulkan) for DirectX 11 compatibility..."
    echo "-------------------------------------------------------------------"
    
    winetricks dxvk
    
    if [[ "$?" == "0" ]];
    then
        touch "$WINEPREFIX/.dx11_enabled"

        echo ""
        echo -e "Prefix ready for running DirectX 11 games.\n"
    fi
}


enable_dx12()
{
    local WINEPREFIX="$1"

    if ! [[ -f "$PREFIX/opt/bin/winetricks" ]];
    then
        abort "Winetricks not found."
    fi

    echo ""
    echo "Installing VKD3D for DirectX 12 compatibility..."
    echo "------------------------------------------------"

    winetricks vkd3d

    if [[ "$?" == "0" ]];
    then
        touch "$WINEPREFIX/.dx12_enabled"
    
        echo ""
        echo -e "Prefix ready for running DirectX 12 games.\n"
    fi
}


enable_virtual_desktop()
{
    if [[ -v WINELOADER ]];
    then
        if ! [[ -v WINE_DESKTOP_RES ]];
        then
            if ! [[ "$1" == "" ]];
            then
                WINE_DESKTOP_RES="$1"
            fi
        fi
                
        if ! [[ -v WINEPREFIX ]];
        then
            if ! [[ "$2" == "" ]];
            then
                WINEPREFIX="$2"
            fi
        fi

        is_wine_prefix "$WINEPREFIX"

        if [[ "$?" == "0" ]];
        then
            load_prefix "$WINEPREFIX"
            
            echo -e "Enabling WINE a $WINE_DESKTOP_RES Virtual Desktop..."
            
            WINE_CMDLINE="reg add "
            WINE_CMDLINE+="\"HKCU\Software\Wine\Explorer\Desktops\" "
            WINE_CMDLINE+="/v Default /t REG_SZ /d $WINE_DESKTOP_RES /f"

            wine $WINE_CMDLINE

            WINE_CMDLINE="reg add "
            WINE_CMDLINE+="\"HKCU\Software\Wine\Explorer\" "
            WINE_CMDLINE+="/v Desktop /t REG_SZ /d Default /f"

            wine $WINE_CMDLINE
        fi
    fi
}


end()
{
    # $1: A return code, if any was provided
    
    if [[ "$0" == *bash ]] || [[ "$0" == *zsh ]];
    then
        return $1
    else
        exit $1
    fi
}


exec_type()
{
    local EXEC=$1
    local FILE_TYPE=$(file -L "$EXEC")

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
    local FULL_PATH=$1

    local FILE_NAME=$(basename "$FULL_PATH")
    local FILE_EXTENSION=${FILE_NAME##*.}

    echo .$FILE_EXTENSION
}


install_wine()
{
    echo -e "Installing Hangover-WINE (WINE for ARM) ..."
    echo -e "-------------------------------------------"

    PKGS="hangover-wine hangover-wowbox64 hangover-libarm64ecfex"
    PKGS+=" hangover-libwow64fex"
        
    pkg install -y $PKGS
}


install_winetricks()
{
    WINETRICKS_URL="https://raw.githubusercontent.com"
    WINETRICKS_URL+="/Winetricks/winetricks/master/src/winetricks"

    if ! [[ -f "$PREFIX/bin/zenity" ]] || [[ -f "$PREFIX/bin/cabextract" ]];
    then
        pkg install -y zenity cabextract
    fi
    
    cd "$TMP"

    curl -LO $WINETRICKS_URL

    chmod +x "$TMP/winetricks"

    cp -u "$TMP/winetricks" "$PREFIX/opt/bin/winetricks"
}


is_wine_installation()
{
    local WINE_PATH="$1"
    
    echo -e "Checking if '$WINE_PATH' is a valid WINE installation..."

    if [[ -d "$WINE_PATH" ]];
    then
        WINE_SERVER=$(find "$WINE_PATH"/** -type f -name "wineserver")

        if ! [[ "$WINE_SERVER" == "" ]];
        then
            echo -e "Seems good.\n"
            
            return 0
        fi
    fi

    echo -e "The wineserver executable was not found. This is bad.\n"
    
    return 1
}


is_wine_prefix()
{
    local PREFIX="$1"

    if [[ -d "$PREFIX" ]];
    then
        if [[ -d "$PREFIX/dosdevices" ]];
        then
            return 0
        fi
    fi

    return 1
}


isolabel()
{
    local ISO=$1
    local EXTENSION=$(filext "$ISO")
    local LC_EXT=$(lowercase "$EXTENSION")
    
    if [[ "$LC_EXT" == ".iso" ]] || [[ "$LC_EXT" == ".bin" ]];
    then
        if [[ -f "$(which /usr/bin/cd-info)" ]];
        then
            LABEL=$(iso-info -d -i "$ISO" | grep -m 1 "Volume id:")
    
            if [[ "$LABEL" == "" ]];
            then
                LABEL=$(iso-info -d -i "$ISO" | grep -m 1 "Volume")
            fi
        fi
    fi

    if ! [[ "$LABEL" == "" ]];
    then
        LABEL=$(echo "$LABEL" | cut -d ':' -f 2 | xargs)
        echo "$LABEL"
    else
        isoname "$ISO"
    fi
}


isoname()
{
    local ISO=$1
    local EXTENSION=$(filext "$ISO")
    local LC_EXT=$(lowercase "$EXTENSION")
    
    local FILE_NAME_WEXT=$(basename "$ISO" $EXTENSION)
    
    if [[ "$FILE_NAME_WEXT" == "" ]];
    then
        echo "UNKNOWN"
    else
        ISO_LABEL=$(uppercase "$FILE_NAME_WEXT")
        ISO_LABEL=$(echo "$ISO_LABEL" | sed 's/ /_/g')
        
        echo "$ISO_LABEL"
    fi
}


load_basic_env()
{
    echo -e "WINE basic environment loaded:\n"
    echo -e "- WINE_PATH: Self explaining"
    echo -e "- WINE_PREFIXES: Prefixes path\n"

    echo -e "Also, the following commands are now available:"
    echo -e ""
    echo -e "disable_virtual_desktop, enable_dx11, enable_dx12,"
    echo -e "enable_virtual_desktop, exec_type, install_wine,"
    echo -e "install_winetricks, isolabel, load_prefix, mount_iso,"
    echo -e "set_default_prefix, setup_prefix\n"

    if ! [[ -v ZSH_VERSION ]];
    then
        export -f disable_virtual_desktop
        export -f enable_dx11
        export -f enable_dx12
        export -f enable_virtual_desktop
        export -f exec_type
        export -f install_wine
        export -f install_winetricks
        export -f isolabel
        export -f load_prefix
        export -f mount_iso
        export -f set_default_prefix
        export -f setup_prefix
    fi 
}


load_prefix()
{
    if ! [[ "$1" =~ "/" ]];
    then
        local PREFIX="$WINE_PREFIXES/$1"
    else
        local PREFIX="$1"
    fi

    is_wine_prefix "$PREFIX"

    if [[ "$?" == "0" ]];
    then
        export WINEPREFIX="$PREFIX"

        if [[ -f "$PREFIX/.arch" ]];
        then
            export WINEARCH=$(cat "$PREFIX/.arch")
        else
            if [[ -d "$PREFIX/drive_c/Program Files (x86)" ]];
            then
                export WINEARCH="win64"
            else
                export WINEARCH="win32"
            fi
        fi
        
        export WIN_C="$WINEPREFIX/drive_c"
        export WIN_D="$WINEPREFIX/drive_d"

        echo -e "WINE prefix '$WINEPREFIX' ($WINEARCH) activated.\n"
    fi
}


load_wine()
{
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
                    export WINEARCH="wow64"
                fi
            fi
        else
            abort "No WINE prefix loaded. Load one first."
        fi
    fi
    
    export WINE32_UTILS="$WINE_PATH/lib/wine/i386-windows"
    export WINE64_UTILS="$WINE_PATH/lib/aarch64-windows"

    if [[ "$WINEARCH" == "wow64" ]];
    then
        export WINE_UTILS="$WINE32_UTILS"
    else
        export WINE_UTILS="$WINE64_UTILS"
    fi

    export WINE_BINARIES="$WINE_PATH/bin"

    export WINEDLLPATH="$WINE_PATH/lib/wine"
    export WINELOADER="$WINE_BINARIES/wine"
    export WINESERVER="$WINE_BINARIES/wineserver"

    export WINEDEBUG="-all"
    
    alias wine="$WINE_BINARIES/wine"
    alias wineboot="\"$WINELOADER\" \"$WINE_UTILS/wineboot.exe\""
    alias winecfg="\"$WINELOADER\" \"$WINE_UTILS/winecfg.exe\""
    alias winedump="\"$WINE_BINARIES/winedump\""
    alias cmd="\"$WINELOADER\" \"$WINE_UTILS/cmd.exe\""
    alias explorer="\"$WINELOADER\" \"$WINE_UTILS/winefile.exe\""
    alias reg="\"$WINELOADER\" \"$WINE_UTILS/reg.exe\""
    alias regedit="\"$WINELOADER\" \"$WINE_UTILS/regedit.exe\""

    echo ""
    echo "WINE environment loaded."
    echo ""
    echo "You have available the following aliases: "
    echo "- wine: WINE executable"
    echo "- wineboot: Performs a 'reboot' of the loaded prefix."
    echo "- explorer, reg, regedit: Launch these Windows programs."
    echo ""
    echo "Also, if you want to see debug information, unset WINEDEBUG."
    echo ""
}


lowercase()
{
    if ! [[ "$1" == "" ]];
    then
        echo "$1" | awk '{print tolower($0)}'
    fi
}


mount_iso()
{
    local ISO=$(realpath "$1")
    local ISO_TYPE=$(lowercase $(filext "$ISO"))
    local LABEL=$(isolabel "$ISO")
    local MOUNT_PATH="$TMP/iso/$LABEL"
    
    if [[ -f "$TMP/iso/.${LABEL}_mounted" ]];
    then
        echo -e "This ISO is already mounted in '$MOUNT_PATH'.\n" && exit 1
    fi
    
    if [[ "$ISO_TYPE" == ".iso" ]] || [[ "$ISO_TYPE" == ".bin" ]];
    then
        mkdir -p "$MOUNT_PATH"
        cd "$MOUNT_PATH"

        if [[ -f "$(which bsdtar)" ]];
        then        
            bsdtar xf "$ISO"
                
        elif [[ -f "$(which 7z)" ]];
        then
            7z x "$ISO"
        else
            echo -e "Can't find bsdtar or 7z. Unable to extract ISO.\n"
            exit 1
        fi

        if ! [[ "$?" == "0" ]];
        then
            echo -e "Failed extracting '$ISO'.\n" && exit 1
        fi

        chmod -R 770 "$MOUNT_PATH"
        touch "$TMP/iso/.${LABEL}_mounted"
        
        echo -e "ISO 'mounted' in '$MOUNT_PATH'.\n"
    fi
}


same_file()
{
    local FIRST_FILE="$1"
    local SECOND_FILE="$2"

    if [[ "$FIRST_FILE" == "" ]] || [[ "$SECOND_FILE" == "" ]];
    then
        return -1
        
    elif ! [[ -f "$FIRST_FILE" ]] || ! [[ -f "$SECOND_FILE" ]];
    then
        return -1
    else
        FIRST_MD5=$(b3sum "$FIRST_FILE" | cut -d ' ' -f 1)
        SECOND_MD5=$(b3sum "$SECOND_FILE" | cut -d ' ' -f 1)

        if [[ "$FIRST_MD5" == "$SECOND_MD5" ]];
        then
            return 0;
        else
            return 1;
        fi
    fi
}


set_default_prefix()
{
    local PREFIX="$1"

    is_wine_prefix "$PREFIX"

    if ! [[ "$?" == "0" ]];
    then
        abort "Invalid prefix '$PREFIX'."
    fi

    if ! [[ -d "$PREFIX/drive_c/Program Files (x86)" ]];
    then
        if [[ -d "$HOME/.wine" ]];
        then
            rm "$HOME/.wine"
        fi
        
        ln -s "$PREFIX" "$HOME/.wine"
        
        echo -e "Prefix '$PREFIX' is now the default for 32 bit.\n"
    else
        if [[ -d "$HOME/.wine64" ]];
        then
            rm "$HOME/.wine64"
        fi
        
        ln -s "$PREFIX" "$HOME/.wine64"
        
        echo -e "Prefix '$PREFIX' is now the default for 64 bit.\n"
    fi
}


setup_prefix()
{
    WINEPREFIX="$1"
    WINEARCH="$2"

    if ! [[ "$WINEARCH" == "win32" ]] && ! [[ "$WINEARCH" == "win64" ]] &&
       ! [[ "$WINEARCH" == "wow64" ]];
    then
        abort "Invalid architecture '$WINEARCH'. Use win32 or win64."
    fi

    if [[ "$WINEARCH" == "win32" ]];
    then
        WINEARCH="wow64"
    fi

    echo -e "Preparing to setup a $WINEARCH prefix in '$WINEPREFIX'...\n"

    PREFIX_PATH=$(dirname "$WINEPREFIX")
    
    if ! [[ -d "$PREFIX_PATH" ]];
    then
        mkdir -p "$PREFIX_PATH"
    fi

    if ! [[ -v WINELOADER ]];
    then
        load_wine
    fi

    "$WINELOADER" "$WINE_UTILS/wineboot.exe"

    if ! [[ "$?" == "0" ]];
    then
        echo -e "Initialization failed.\n"
        echo -e "May be a permissions problem creating the prefix..."
        echo -e "...or some WINE dependencies may be missing..."
        exit 1
    fi

    echo "$WINEARCH" > "$WINEPREFIX/.arch"

    if [[ "$WINEARCH" == "wow64" ]] && ! [[ -d "$HOME/.wine" ]];
    then
        set_default_prefix "$WINEPREFIX"
        
    elif [[ "$WINEARCH" == "win64" ]] && ! [[ -d "$HOME/.wine64" ]];
    then
        set_default_prefix "$WINEPREFIX"
    fi
}


update_script()
{
    local SCRIPT="$TMP/twine.sh"
    local SCRIPT_FILE=$(basename "$SCRIPT")
    
    local INSTALL_PATH="$PREFIX/opt/bin"

    SCRIPT_URL="https://github.com/aribrew/wine-utils"
    SCRIPT_URL+="/raw/refs/heads/main/twine.sh"
    
    if ! [[ -d "$INSTALL_PATH" ]];
    then
        mkdir -p "$INSTALL_PATH"
    fi

    echo -e "Checking for twine.sh updates..."

    SAVED=$(pwd)
    cd "$TMP"
    curl -sLO $SCRIPT_URL
    cd "$SAVED"

    if [[ -f "$INSTALL_PATH/$SCRIPT_FILE" ]];
    then
        same_file "$INSTALL_PATH/$SCRIPT_FILE" "$SCRIPT"
    
        if [[ "$?" == "1" ]];
        then
            cp -u "$SCRIPT" "$INSTALL_PATH/$SCRIPT_FILE"
            echo -e "Your twine.sh has been updated.\n"
        else
            echo -e "You are using the latest twine.sh\n"
        fi
    else
        cp "$SCRIPT" "$INSTALL_PATH/$SCRIPT_FILE"
        echo -e "The twine.sh script has been installed in $PREFIX/opt/bin.\n"
    fi
}


usage()
{
    echo -e "Twine.sh is a LARGE script created as helper for working with"
    echo -e "WINE and it's prefixes in Termux."
    echo -e ""
    echo -e "You can easily install wine, create prefixes, load and"
    echo -e "configure them, and more."
    echo -e ""
    echo -e "If executed with '.' or 'source', when loading WINE and"
    echo -e "prefixes, they will be loaded into the current shell session,"
    echo -e "and you will have available a bunch of commands and environment"
    echo -e "variables."
    echo -e ""
    echo -e " -- Made by aribrew (arithesage@protonmail.com)"
    echo -e ""
    echo -e ""
    echo -e "Usage: "
    echo -e ""
    echo -e "twine.sh <executable> [args]"
    echo -e ": Executes a program with the default prefix."
    echo -e ""
    echo -e "  If a file {executable}_winecfg is found, and contains"
    echo -e "  variables such as WINEPREFIX, this configuration will be"
    echo -e "  used instead the default one."
    echo -e ""
    echo -e "  Same if you export a WINEPREFIX variable manually."
    echo -e ""
    echo -e "twine.sh --config [prefix]"
    echo -e ": Configs the specified prefix."
    echo -e "  If no prefix is provided, and one is already loaded into the"
    echo -e "  current shell session, it will be the one to configure."
    echo -e ""
    echo -e "twine.sh --set_default_prefix <prefix name/path>"
    echo -e ": Set the default WINE prefix to use"
    echo -e ""
    echo -e "twine.sh --setup_prefix <prefix name>"
    echo -e ": Create a new prefix in ~/.local/share/wineprefixes."
    echo -e ""
    echo -e "twine.sh --load_prefix <WINE prefix name/path>"
    echo -e ": Load the given WINE prefix."
    echo -e ""
    echo -e "twine.sh --load_basic_env"
    echo -e ": Only loads the minimal environment."
    echo -e ""
    echo -e "twine.sh --disable_virtual_desktop [prefix]"
    echo -e ": Enables the Virtual Desktop for the given or actual prefix."
    echo -e ""
    echo -e "twine.sh --enable_dx11_support <prefix>"
    echo -e ": Enable DirectX 11 support for the given prefix."
    echo -e ""
    echo -e "twine.sh --enable_dx12_support <prefix>"
    echo -e ": Enable DirectX 12 support for the given prefix."
    echo -e ""
    echo -e "twine.sh --enable_virtual_desktop <resolution> [prefix]"
    echo -e ": Enables the Virtual Desktop for the given or actual prefix."
    echo -e ""
    echo -e "twine.sh --install"
    echo -e ": Installs WINE."
    echo -e ""
    echo -e "twine.sh --install_app <app.exe|.iso|.zip>"
    echo -e ": Installs the given app. It can be an EXE installer, an ISO"
    echo -e "  image or a ZIP. You can tweak various things exporting the "
    echo -e "  folloing variables: WIN_INSTALL_PREFIX, WIN_INSTALL_WINVER, "
    echo -e "  WIN_INSTALL_APPNAME."
    echo -e ""
    echo -e "  If an ISO or ZIP is provided, it will be extracted. Also, in"
    echo -e "  this case, you can provide WIN_INSTALL_SETUP_EXEC, to run that"
    echo -e "  after extraction. If not, the script will attempt to find it."
    echo -e ""
    echo -e "twine.sh --install_winetricks"
    echo -e ": Downloads Winetricks into ~/.local/bin/wine."
    echo -e "  Also install its dependencies."
    echo -e ""
    echo -e "twine.sh --update"
    echo -e ": Updates the twine.sh script."
    echo -e ""
}


if [[ "$1" == "" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    abort
fi


if ! [[ -v TERMUX_VERSION ]];
then
    abort "This script is for Termux only."
fi


TMP="$HOME/tmp"

export WINE_PATH="$PREFIX/opt/hangover-wine"
export WINE_PREFIXES="$HOME/.local/share/wineprefixes"


if [[ "$1" == "--config" ]];
then
    if [[ -v WINEPREFIX ]];
    then
        echo -e "Configuring loaded WINE prefix '$WINEPREFIX'..."
        "$WINELOADER" "$WINE_UTILS/winecfg.exe"
    else
        if ! [[ "$2" == "" ]];
        then
            WINEPREFIX="$2"

            if ! [[ "$WINEPREFIX" =~ "/" ]];
            then
                WINEPREFIX="$WINE_PREFIXES/$WINEPREFIX"
            fi

            is_wine_prefix "$WINEPREFIX"

            if [[ "$?" == "0" ]];
            then
                load_prefix "$WINEPREFIX"
            fi

            echo -e "Configuring WINE prefix '$WINEPREFIX'..."
            "$WINELOADER" "$WINE_UTILS/winecfg.exe"
        fi
    fi

    end $?
    
elif [[ "$1" == "--set_default_prefix" ]];
then
    if ! [[ "$2" == "" ]];
    then
        if [[ -d "$2" ]];
        then
            is_wine_prefix "$2"

            if [[ "$?" == "0" ]];
            then
                set_default_prefix "$2"
            fi
            
        elif ! [[ -f "$2" ]] && ! [[ -d "$2" ]];
        then
            is_wine_prefix "$2"

            if [[ "$?" == "0" ]];
            then
                set_default_prefix "$2"
            fi
        fi
    fi

    end $?

elif [[ "$1" == "--setup_prefix" ]];
then
    if [[ "$2" == "" ]];
    then
        echo -e "No prefix specified."
        echo -e "Will create the default for 64 bits.\n"

        WINEPREFIX="$WINE_PREFIXES/.wine64"
        WINEARCH="win64"
    else
        if [[ "$3" == "" ]];
        then
            echo -e "No architecture specified."
            echo -e "Will create the prefix for 64 bits.\n"
            
            WINEPREFIX="$2"
            WINEARCH="win64"
        else
            WINEPREFIX="$2"
            WINEARCH="$3"
        fi
    fi

    if [[ "$WINEPREFIX" =~ "/" ]];
    then
        setup_prefix "$WINEPREFIX" $WINEARCH
    else
        setup_prefix "$WINE_PREFIXES/$WINEPREFIX" $WINEARCH
    fi

    end $?

elif [[ "$1" == "--load_prefix" ]];
then
    if ! [[ "$2" == "" ]];
    then
        if [[ -d "$2" ]];
        then
            is_wine_prefix "$2"

            if [[ "$?" == "0" ]];
            then
                load_prefix "$2"
            else
                abort "Not a valid WINE prefix."
            fi
            
        elif ! [[ -f "$2" ]] && ! [[ -d "$2" ]];
        then
            is_wine_prefix "$2"

            if [[ "$?" == "0" ]];
            then
                load_prefix "$2"
            fi
        fi
    else
        if [[ -v WINELOADER ]];
        then
            if [[ -d "$HOME/.wine64" ]];
            then
                load_prefix "$HOME/.wine64"
            else
                abort "No default WINE prefix set."
            fi
        fi
    fi

    end $?

elif [[ "$1" == "--load_basic_env" ]];
then
    load_basic_env
    end $?

elif [[ "$1" == "--enable_virtual_desktop" ]];
then
    if ! [[ "$1" == "" ]];
    then
        WINEPREFIX="$1"
        WINE_DESKTOP_RES="$2"

        enable_virtual_desktop "$WINEPREFIX" "$WINE_DESKTOP_RES"
    fi

    end $?

elif [[ "$1" == "--disable_virtual_desktop" ]];
then
    if ! [[ "$1" == "" ]];
    then
        WINEPREFIX="$1"
        
        disable_virtual_desktop "$WINEPREFIX"
    fi

    end $?


elif [[ "$1" == "--enable_dx11_support" ]];
then
    if ! [[ "$2" == "" ]];
    then
        WINEPREFIX="$2"
    
        is_wine_prefix "$WINEPREFIX"
    
        if [[ "$?" == "0" ]];
        then
            load_prefix "$WINEPREFIX"
            enable_dx11_support "$WINEPREFIX"
        fi
    fi
    
    end $?

elif [[ "$1" == "--enable_dx12_support" ]];
then
    if ! [[ "$2" == "" ]];
    then
        WINEPREFIX="$2"
    
        is_wine_prefix "$WINEPREFIX"
    
        if [[ "$?" == "0" ]];
        then
            load_prefix "$WINEPREFIX"
            enable_dx12_support "$WINEPREFIX"
        fi
    fi
    
    end $?

elif [[ "$1" == "--install" ]];
then
    install_wine

    end $?

elif [[ "$1" == "--install_app" ]];
then
    if ! [[ "$2" == "" ]] && [[ -f "$2" ]];
    then
        APP="$2"

        if [[ -v WIN_INSTALL_PREFIX ]];
        then
            export WINEPREFIX="$WIN_INSTALL_PREFIX"
            
        elif [[ -v WIN_INSTALL_WINARCH ]];
        then
            export WINARCH="$WIN_INSTALL_WINARCH"

        elif [[ -v WIN_INSTALL_WINVER ]];
        then
            export WINEPREFIX="$WIN_INSTALL_WINVER"
        fi
        
        if [[ "$APP" == *.exe ]];
        then
            echo -e "Install app from EXE: TODO\n"
            
        elif [[ "$APP" == *.iso ]];
        then
            echo -e "Install app from ISO: TODO\n"

        elif [[ "$APP" == *.zip ]];
        then
            echo -e "Install app from ZIP: TODO\n"
        fi
    fi
    
    end $?

elif [[ "$1" == "--install_winetricks" ]];
then
    install_winetricks
    end $?

elif [[ "$1" == "--update" ]];
then
    update_script
    end $?
fi


if ! [[ "$0" == "SHELL" ]] && ! [[ "$1" == "" ]] && [[ -f "$1" ]];
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

    if [[ -v WIN_VERSION ]];
    then
        PREFIX="$WINE_PREFIXES/$WIN_VERSION"
        
        if ! [[ -d "$PREFIX" ]];
        then
            abort "Requested WINE prefix '$PREFIX' does not exist."
        else
            load_prefix "$PREFIX"
        fi
    fi

    if ! [[ -d "$WINEPREFIX" ]];
    then
        if ! [[ -d "$WINE_PREFIXES/$WINEPREFIX" ]];
        then
            abort "Requested WINE prefix '$WINEPREFIX' does not exist."
        else
            load_prefix "$WINEPREFIX"
        fi
    fi

    if ! [[ -v WINELOADER ]];
    then
        if [[ "$WINE_PATH" ]];
        then
            load_wine "$WINE_PATH"
        else
            load_wine
        fi
    fi

    if [[ -v WINEPREFIX ]] && [[ -v WINELOADER ]];
    then
        "$WINELOADER" "$EXEC" "$ARGS"
    fi
fi

