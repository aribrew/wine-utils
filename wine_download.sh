#!/bin/bash

SCRIPT_HOME=$(realpath $(dirname $0))

source "bash_helpers"


download_wine()
{
    local WINE_BRANCH="$1"
    local WINE_VERSION="$2"

    if [[ "$WINE_BRANCH" == "" ]];
    then
        WINE_BRANCH="stable"
    fi

    if [[ "$WINE_VERSION" == "" ]];
    then
        WINE_VERSION="11.0.0.0"
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

    echo -e "\nAll the needed packages downloaded.\n"

    WINE_TMP_PATH="$TMP/wine/$WINE_BRANCH/$WINE_VERSION"

    if [[ -d "$WINE_TMP_PATH" ]];
    then
        rm -r "$WINE_TMP_PATH"
    fi

    mkdir -p "$WINE_TMP_PATH"

    mv wine-*.deb "$WINE_TMP_PATH"
}


extract_wine()
{
    local PACKAGE="$1"
    local INSTALL_PATH="$2"

    if [[ "$INSTALL_PATH" == "" ]];
    then
        INSTALL_PATH="$WINE_ENV"
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

    echo -e "\nAll packages extracted. Checking if we have a valid WINE...\n"

    is_wine_installation "$INSTALL_PATH/$WINE_FOLDER"

    if [[ "$?" == "0" ]];
    then
        echo "$WINE_VERSION" > "$INSTALL_PATH/$WINE_FOLDER/.wine_version"
        echo "$WINE_BRANCH" > "$INSTALL_PATH/$WINE_FOLDER/.wine_branch"

        echo -e "\nAll done.\n"

        rm -r "$WINE_TMP"
    else
        abort "Something failed. Cannot validate WINE installation."
    fi
}


is_wine_installation()
{
    local WINE_PATH="$1"

    echo -e "Checking for a valid WINE installation at '$WINE_PATH' ..."

    if [[ -d "$WINE_PATH" ]];
    then
        WINE_SERVER=$(find "$WINE_PATH"/** -type f -name "wineserver")

        if ! [[ "$WINE_SERVER" == "" ]];
        then
            echo -e "Seems good.\n"

            return 0
        fi
    fi

    echo -e "The wineserver executable was not found."
    echo -e "If extracting to /tmp/wine, this can be ignored.\n"

    return 1
}


usage()
{
    echo -e "Usage: \n"
    echo -e "wine_download.sh [branch] [version]"
    echo -e ": Downloads and extracts WINE to $TMP/wine folder."
    echo -e "  Default branch and version: stable 11.0.0.0\n"
}


if [[ "$1" == "" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    abort
fi


if [[ -v TERMUX_VERSION ]];
then
    abort "Install hangover-wine package instead."
else
    TMP="/tmp"
fi


WINE_BRANCH="$1"
WINE_VERSION="$2"

download_wine $WINE_BRANCH $WINE_VERSION

WINE_TMP_PATH="$TMP/wine/$WINE_BRANCH/$WINE_VERSION"

if [[ -d "$WINE_TMP_PATH" ]];
then
    extract_wine "$WINE_TMP_PATH" "$WINE_TMP_PATH"
fi
