#!/bin/bash

source bash_helpers.sh

if ! [[ -v BASH_HELPERS_LOADED ]];
then
    echo -e "BASH helpers not found in PATH. Install it first.\n"
    exit 1
fi


usage()
{
    echo -e "Usage: win_start.sh <executable> [args]\n"

    echo -e "To force a specific prefix or WINE version, export"
    echo -e "WINE_PREFIX_NAME and/or WINE_INSTALL_PATH.\n"

    echo -e "Also, if a file .{executable}_winecfg exists along with the"
    echo -e "executable file, the needed WINE configuration will be "
    echo -e "automatically loaded.\n"
}


if [[ "$1" == "" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    abort
fi


if ! [[ -v WINE_ENV ]] && [[ -f "$HOME/.local/bin/winenv/.wine_env" ]];
then
    source "$HOME/.local/bin/winenv/.wine_env"
fi


EXEC=$(realpath "$1")


if ! [[ "$EXEC" == "" ]] && [[ -f "$EXEC" ]];
then
    EXEC_PATH=$(dirname "$EXEC")
    EXEC_FILENAME=$(basename "$EXEC")
    EXEC_FILENAME_WITHOUT_EXT=$(filext "$EXEC_FILENAME")

    EXEC_WINECFG=".$(lowercase "$EXEC_FILENAME_WITHOUT_EXT")_winecfg"
    
    if ! [[ -v WINE_ENV ]];
    then
        abort "Cannot find WINE_ENV var. WINE environment not loaded."
    fi

    ARGS=${@:2}

    if [[ -f "$EXEC_PATH/$EXEC_WINECFG" ]];
    then
        source "$EXEC_PATH/$EXEC_WINECFG"

        echo -e "Loaded executable custom WINE config.\n"
    fi

    if [[ -v WINE_INSTALL_PATH ]];
    then
        if ! [[ -f "$WINE_INSTALL_PATH/.wine_version" ]];
        then
            abort "Invalid WINE installation in '$WINE_INSTALL_PATH'."
        else
            . wine_load.sh "$WINE_INSTALL_PATH"
        fi
    fi

    if [[ -v WINE_PREFIX_NAME ]];
    then
        if ! [[ -f "$HOME/.local/share/wineprefix/$WINE_PREFIX_NAME" ]];
        then
            abort "Invalid WINE prefix '$WINE_PREFIX_NAME'."
        else
            . "$HOME/.local/share/wineprefix/$WINE_PREFIX_NAME/activate"
        fi
    fi

    if ! [[ -v WINE_PREFIX_NAME ]] && ! [[ -v WINE_INSTALL_PATH ]];
    then
        EXEC_TYPE=$(exec_type "$EXEC")

        if [[ "$EXEC_TYPE" == "windows-i386" ]];
        then
            if ! [[ -f "$WINE_ENV/.default_wine32" ]];
            then
                abort "Install a WINE version for 32 bits apps."
            fi

            if ! [[ -d "$HOME/.wine/dosdevices" ]];
            then
                echo "Install a WINE prefix for win32 apps."
                abort "Or set a existing one the default."
            fi

            if ! [[ -v WINE_INSTALL_PATH ]];
            then
                . wine_load.sh $(cat "$WINE_ENV/.default_wine32");
            else
                if ! [[ -f "$WINE_INSTALL_PATH/.wine_version" ]];
                then
                    abort "Invalid WINE installation in '$WINE_INSTALL_PATH'."
                else
                    . wine_load.sh "$WINE_INSTALL_PATH"
                fi
            fi

            if ! [[ -v WINE_PREFIX_NAME ]];
            then
                . "$HOME/.wine/activate"
            else
                if ! [[ -f "$HOME/.local/share/wineprefix/$WINE_PREFIX_NAME" ]];
                then
                    abort "Invalid WINE prefix '$WINE_PREFIX_NAME'."
                else
                    . "$HOME/.local/share/wineprefix/$WINE_PREFIX_NAME/activate"
                fi
            fi
            
        elif [[ "$EXEC_TYPE" == "windows-amd64" ]];
        then
            if ! [[ -f "$WINE_ENV/.default_wine64" ]];
            then
                abort "Install a WINE version for 64 bits apps."
            fi

            if ! [[ -d "$HOME/.wine64/dosdevices" ]];
            then
                abort "Install a WINE prefix for win64 apps."
            fi

            . wine_load.sh $(cat "$WINE_ENV/.default_wine64")
            . "$HOME/.wine64/activate"
        else
            abort "The specified executable isn't a Windows 32/64 bit one."
        fi
    fi

    if [[ -v WINELOADER ]] && [[ -v WINEPREFIX ]];
    then
        echo -en "Launching '$EXEC'"

        if ! [[ "$ARGS" == "" ]];
        then
            echo -en " with args '$ARGS'"
        fi
        
        echo -e " ..."
        
        "$WINELOADER" "$EXEC" "$ARGS"
    fi
fi
