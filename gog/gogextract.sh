#!/bin/bash

if ! [[ "$1" == "" ]];
then
    INSTALLER="$1"
    INSTALL_PATH="$2"

    if [[ "$INSTALL_PATH" == "" ]];
    then
        INSTALL_PATH="$HOME/tmp"
    fi
    
    if ! [[ -d "$INSTALL_PATH" ]];
    then
        mkdir -p "$INSTALL_PATH"
    fi

    if [[ -f "$INSTALLER" ]] && [[ "$INSTALLER" == *.exe ]];
    then
        innoextract -g -m -d "$INSTALL_PATH" "$INSTALLER"
    else
        if [[ -d "$INSTALLER" ]];
        then
            GAME_NAME=$(realpath $(basename "$INSTALLER"))
            INSTALLER_EXE=$(ls "$INSTALLER"/setup_${GAME_NAME}*.exe)

            if [[ -f "$INSTALLER_EXE" ]];
            then
                innoextract -d "$INSTALL_PATH" "$INSTALLER_EXE"
            fi
        fi
    fi

    if [[ -f "$INSTALL_PATH/app/webcache.zip" ]];
    then
        mv "$INSTALL_PATH/app/"* "$INSTALL_PATH/"

        if [[ -d "$INSTALL_PATH/__support/app" ]];
        then
            mv "$INSTALL_PATH/__support/app/"* "$INSTALL_PATH/"
            rm -r "$INSTALL_PATH/__support"
        fi
        
        rm -r "$INSTALL_PATH/app"
    fi
fi
