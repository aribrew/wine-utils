#!/bin/bash

BASH_HELPERS="/opt/bin/bash_helpers"
SCRIPTS=$(realpath $(dirname $0))


if ! [ -f "$BASH_HELPERS" ] &&
     [ -f "$SCRIPTS/bash_helpers" ];
then
    "$SCRIPTS/helpers/bash_helpers" install
fi


if ! [ -f "$BASH_HELPERS" ];
then
    echo "Cannot find /opt/bin/bash_helpers."
    echo ""

    exit 1
    
else
    source "$BASH_HELPERS"
fi




WINE_TMP="/tmp/wine-tmp"

mkdir -p "$WINE_TMP"
cd "$WINE_TMP"


if ! [ -v OS_ARCH ];
then
    if [ "$(uname -m)" == "x86_64" ];
    then
        export OS_ARCH="both"
    else
        export OS_ARCH="i386"
    fi
fi


OS_VERSION=$(cat /etc/os-release | grep "^VERSION_CODENAME=" | cut -d '=' -f 2)


if ! [ -v WINE_BRANCH ];
then
    export WINE_BRANCH="stable"
fi

if ! [ -v WINE_VERSION ];
then
    export WINE_VERSION="10.0.0.0"
fi


if [ "$OS_ARCH" == "i386" ] || [ "$OS_ARCH" == "both" ];
then
    echo ""
    echo "Enabling i386 repository if not available yet ..."

    sudo dpkg --add-architecture i386
fi


echo ""
echo "Refreshing APT database ..."
echo "---------------------------"

sudo apt update

if ! [ "$?" == "0" ];
then
    abort "Something is wrong with APT. Fix it first."
fi


if [ "$OS_ARCH" == "i386" ] || [ "$OS_ARCH" == "both" ];
then
    echo ""
    echo "Downloading WINE (32 bit) ($WINE_BRANCH) $WINE_VERSION) ..."
    echo "-----------------------------------------------------------"

    WINE_i386_1="wine-${WINE_BRANCH}:i386"
    WINE_i386_1+="=${WINE_VERSION}"
    WINE_i386_1+="~${OS_VERSION}-1"

    WINE_i386_2="wine-${WINE_BRANCH}-i386"
    WINE_i386_2+="=${WINE_VERSION}"
    WINE_i386_2+="~${OS_VERSION}-1"

    apt download $WINE_i386_1
    apt download $WINE_i386_2
fi


if [ "$OS_ARCH" == "amd64" ] || [ "$OS_ARCH" == "both" ];
then
    echo ""
    echo "Downloading WINE (64 bit) ($WINE_BRANCH) ($WINE_VERSION) ..."
    echo "------------------------------------------------------------"

    WINE_amd64_1="wine-${WINE_BRANCH}:amd64"
    WINE_amd64_1+="=${WINE_VERSION}"
    WINE_amd64_1+="~${OS_VERSION}-1"

    WINE_amd64_2="wine-${WINE_BRANCH}-amd64"
    WINE_amd64_2+="=${WINE_VERSION}"
    WINE_amd64_2+="~${OS_VERSION}-1"

    apt download $WINE_amd64_1
    apt download $WINE_amd64_2
fi


echo ""
echo "Extracting WINE ..."
echo "-------------------"

WINE32_DIR="wine-${WINE_VERSION}_i386"
WINE64_DIR="wine-${WINE_VERSION}_amd64"


if [ "$OS_ARCH" == "i386" ] || [ "$OS_ARCH" == "both" ];
then
    ls *_i386.deb > /dev/null

    if ! [ "$?" == "0" ];
    then
        abort "Failed. WINE i386 packages may have failed downloading..."
    fi

    for package in $(ls *_i386.deb);
    do
        dpkg-deb -x $package $WINE32_DIR

        if ! [ "$?" == "0" ];
        then
        abort "Failed extracting '$package' in '$WINE32_DIR'."
        fi
    done

    echo "$WINE_BRANCH" > "$WINE32_DIR/.wine_branch"
    echo "$WINE_VERSION" > "$WINE32_DIR/.wine_version"
    echo "i386" > "$WINE32_DIR/.wine_arch"

    echo "WINE (32 bit) extracted in $WINE_TMP/$WINE32_DIR."
fi


if [ "$OS_ARCH" == "amd64" ] || [ "$OS_ARCH" == "both" ];
then
    ls *_amd64.deb > /dev/null

    if ! [ "$?" == "0" ];
    then
        abort "Failed. WINE amd64 packages may have failed downloading..."
    fi

    for package in $(ls *_amd64.deb);
    do
        dpkg-deb -x $package $WINE64_DIR

        if ! [ "$?" == "0" ];
        then
            abort "Failed extracting '$package' in '$WINE64_DIR'."
        fi
    done

    echo "$WINE_BRANCH" > "$WINE64_DIR/.wine_branch"
    echo "$WINE_VERSION" > "$WINE64_DIR/.wine_version"
    echo "amd64" > "$WINE64_DIR/.wine_arch"

    echo "WINE (64 bit) extracted in $WINE_TMP/$WINE64_DIR."
fi
