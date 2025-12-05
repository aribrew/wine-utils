#!/bin/bash

source bash_helpers.sh

if ! [[ -v BASH_HELPERS_LOADED ]];
then
    echo -e "BASH helpers not found in PATH. Install it first.\n"
    exit 1
fi


usage()
{
    echo "Usage: download_wine.sh [--web]"
    echo ""
    echo ""
    echo ""
}




if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    abort
fi


OS_ARCH=$(uname -m)
OS_NAME=$(os_name)
OS_VERSION=$(os_version)
LATEST_DEBIAN="trixie"

if [[ "$OS_ARCH" == "x86_64" ]];
then
    export OS_ARCH="amd64"
else
    export OS_ARCH="i386"
fi


if [[ "$OS_ARCH" == "i386" ]];
then
    abort "This script is only intended for 64 bit systems."
fi


if [[ "$1" == "--web" ]] || [[ "$OS_VERSION" == "rolling" ]];
then
    USE_WEB_DOWNLOAD=1

    WINE_URL="https://dl.winehq.org/wine-builds/debian/pool/main/w"
    
    if [[ -d "$WEB_TMP" ]];
    then
        rm -r "$WEB_TMP"
    fi
fi


if [[ -v USE_WEB_DOWNLOAD ]];
then
    OS_VERSION="$LATEST_DEBIAN"
fi


WINE_TMP="/tmp/wine-tmp"
WEB_TMP="/tmp/ar"


mkdir -p "$WINE_TMP"
cd "$WINE_TMP"


if ! [[ -v WINE_BRANCH ]]; 
then
    export WINE_BRANCH="stable"
fi

if ! [[ -v WINE_VERSION ]]; 
then
    export WINE_VERSION="10.0.0.0"
fi


WINE_BASE_PKG="wine-${WINE_BRANCH}_${WINE_VERSION}~${OS_VERSION}"
WINE_BASE_PKG+="-1_amd64.deb"

WINE_i386_PKG="wine-${WINE_BRANCH}-i386_${WINE_VERSION}~${OS_VERSION}"
WINE_i386_PKG+="-1_i386.deb"

WINE_amd64_PKG="wine-${WINE_BRANCH}-amd64_${WINE_VERSION}~${OS_VERSION}"
WINE_amd64_PKG+="-1_amd64.deb"


if ! [[ -v USE_WEB_DOWNLOAD ]];
then
    echo ""
    echo "Enabling i386 repository if not available yet ..."

    sudo dpkg --add-architecture i386

    echo ""
    echo "Refreshing APT database ..."
    echo "---------------------------"

    sudo apt update

    if ! [[ "$?" == "0" ]]; 
    then
        abort "Something is wrong with APT. Fix it first."
    fi
fi


echo ""
echo "Downloading WINE (32 bit) ($WINE_BRANCH) ($WINE_VERSION) ..."
echo "-------------------------------------------------------------"

if [[ -f "$WINE_TMP/$WINE_BASE_PKG" ]] &&
    [[ -f "$WINE_TMP/$WINE_i386_PKG" ]];
then
    echo "Already downloaded. Using the existing files."
else    
    if ! [[ -v USE_WEB_DOWNLOAD ]];
    then
        WINE_BASE="wine-${WINE_BRANCH}"
        WINE_BASE+="=${WINE_VERSION}"
        WINE_BASE+="~${OS_VERSION}-1"
            
        WINE_i386="wine-${WINE_BRANCH}-i386"
        WINE_i386+="=${WINE_VERSION}"
        WINE_i386+="~${OS_VERSION}-1"

        apt download $WINE_BASE
        apt download $WINE_i386
    else
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

        curl -LO "$BASE_URL/$WINE_BASE"

        if ! [[ "$?" == "0" ]];
        then
            abort "Failed downloading base WINE package."
        fi

        curl -LO "$BASE_URL/$WINE_i386"

        if ! [[ "$?" == "0" ]];
        then
            abort "Failed downloading arch-specific WINE package."
        fi
    fi
fi


echo ""
echo "Downloading WINE (64 bit) ($WINE_BRANCH) ($WINE_VERSION) ..."
echo "------------------------------------------------------------"

if [[ -f "$WINE_TMP/$WINE_BASE_PKG" ]] &&
    [[ -f "$WINE_TMP/$WINE_amd64_PKG" ]];
then
    echo "Already downloaded. Using the existing files."
else    
    if ! [[ -v USE_WEB_DOWNLOAD ]];
    then
        WINE_BASE="wine-${WINE_BRANCH}"
        WINE_BASE+="=${WINE_VERSION}"
        WINE_BASE+="~${OS_VERSION}-1"
                    
        WINE_amd64="wine-${WINE_BRANCH}-amd64"
        WINE_amd64+="=${WINE_VERSION}"
        WINE_amd64+="~${OS_VERSION}-1"
        
        apt download $WINE_BASE
        apt download $WINE_amd64
    else
        WINE_BASE="wine-${WINE_BRANCH}"
        WINE_BASE+="_${WINE_VERSION}"
        WINE_BASE+="~${LATEST_DEBIAN}-1_amd64.deb"
                    
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

        curl -LO "$BASE_URL/$WINE_BASE"

        if ! [[ "$?" == "0" ]];
        then
            abort "Failed downloading base WINE package."
        fi

        curl -LO "$BASE_URL/$WINE_amd64"

        if ! [[ "$?" == "0" ]];
        then
            abort "Failed downloading arch-specific WINE package."
        fi
    fi
fi


echo ""
echo "Extracting WINE ..."
echo "-------------------"

WINE_DIR="wine-${WINE_VERSION}"

if ! [[ -f "$WINE_BASE_PKG" ]] || ! [[ -f "$WINE_i386_PKG" ]];
then
    abort "Failed. WINE i386 packages may have failed downloading..."
fi

if ! [[ -v USE_WEB_DOWNLOAD ]];
then
    dpkg-deb -x $WINE_BASE_PKG $WINE_DIR
    dpkg-deb -x $WINE_i386_PKG $WINE_DIR

    if ! [[ "$?" == "0" ]]; 
    then
        abort "Failed extracting WINE (32 bit)."
    fi
else
    mkdir -p "$WEB_TMP/wine"
    mkdir -p "$WEB_TMP/wine_1"
    mkdir -p "$WEB_TMP/wine_2"

    ar x $WINE_BASE_PKG --output "$WEB_TMP/wine_1"
    ar x $WINE_i386_PKG --output "$WEB_TMP/wine_2"

    if [[ "$?" == "0" ]];
    then
        tar xf "$WEB_TMP/wine_1/data.tar.xz" -C "$WEB_TMP/wine"
        tar xf "$WEB_TMP/wine_2/data.tar.xz" -C "$WEB_TMP/wine"

        if [[ "$?" == "0" ]];
        then
            mv "$WEB_TMP/wine/opt" $WINE_DIR/
            mv "$WEB_TMP/wine/usr" $WINE_DIR/

            rm -r "$WEB_TMP"
        fi
    fi
fi


if ! [[ -f "$WINE_BASE_PKG" ]] || ! [[ -f "$WINE_amd64_PKG" ]];
then
    abort "Failed. WINE amd64 packages may have failed downloading..."
fi

if ! [[ -v USE_WEB_DOWNLOAD ]];
then
    dpkg-deb -x $WINE_amd64_PKG $WINE_DIR
    
    if ! [[ "$?" == "0" ]]; 
    then
        abort "Failed extracting WINE (64 bit)."
    fi
else
    mkdir -p "$WEB_TMP/wine"
    mkdir -p "$WEB_TMP/wine_1"
    mkdir -p "$WEB_TMP/wine_2"

    ar x $WINE_BASE_PKG --output "$WEB_TMP/wine_1"
    ar x $WINE_amd64_PKG --output "$WEB_TMP/wine_2"

    if [[ "$?" == "0" ]];
    then
        tar xf "$WEB_TMP/wine_1/data.tar.xz" -C "$WEB_TMP/wine"
        tar xf "$WEB_TMP/wine_2/data.tar.xz" -C "$WEB_TMP/wine"
        
        if [[ "$?" == "0" ]];
        then
            mv "$WEB_TMP/wine/opt" $WINE64_DIR/
            mv "$WEB_TMP/wine/usr" $WINE64_DIR/

            rm -r "$WEB_TMP"
        fi
    fi
fi


echo "$WINE_BRANCH" > "$WINE_DIR/.wine_branch"
echo "$WINE_VERSION" > "$WINE_DIR/.wine_version"

echo "$WINE_TMP/$WINE_DIR" > /tmp/.last_wine_download


echo -e "WINE extracted in $WINE_DIR.\n"
