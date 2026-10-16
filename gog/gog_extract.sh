#!/bin/bash

if ! [[ "$1" == "" ]];
then
    INSTALLER="$1"
    INSTALL_PATH="$2"

    if [[ -d "$INSTALLER" ]];
    then
        GAME_NAME=$(realpath $(basename "$INSTALLER"))
        INSTALLER_EXE=$(ls "$INSTALLER"/setup_${GAME_NAME}*.exe)

        if [[ "$INSTALLER_EXE" == "" ]];
        then
            echo -e "No GOG setup executable found in '$INSTALLER'.\n"
            exit 1
        fi

        INSTALLER="$INSTALLER_EXE"

    elif [[ -f "$INSTALLER" ]] && ! [[ $INSTALLER == *.exe ]];
    then
        echo -e "The provided file isn't a Windows executable.\n"
        exit 1
    fi

    if [[ "$INSTALL_PATH" == "" ]];
    then
        GAME_NAME=$(echo "$INSTALLER" | cut GAME_NAME -d '_' -f 2)
        INSTALL_PATH="$HOME/tmp/$GAME_NAME"
    fi

    if ! [[ -d "$INSTALL_PATH" ]];
    then
        mkdir -p "$INSTALL_PATH"
    fi

    innoextract -g -m -d "$INSTALL_PATH" "$INSTALLER"

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
