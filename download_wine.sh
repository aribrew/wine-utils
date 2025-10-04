#!/bin/bash

source bash_helpers.sh

if ! [[ -v BASH_HELPERS_LOADED ]];
then
    echo -e "BASH helpers not found in PATH. Install it first.\n"
    exit 1
fi


usage()
{
    echo "Usage: download_wine.sh [--web-download]"
    echo ""
    echo ""
    echo ""
}




if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    abort
fi


OS_NAME=$(os_name)
OS_VERSION=$(os_version)


if [[ "$OS_NAME" == "arch" ]];
then
    echo "ArchLinux detected. You can download WINE BUT ArchLinux does not "
    echo "support 32 bit software, so, you cannot run WINE for i386, and so, "
    echo "32 bit Windows applications will be run unsig WOW64."
    echo ""
fi


if [[ "$1" == "--web-download" ]] || [[ "$OS_VERSION" == "rolling" ]];
then
    USE_WEB_DOWNLOAD=1
fi


WINE_URL="https://dl.winehq.org/wine-builds/debian/pool/main/w"
WINE_TMP="/tmp/wine-tmp"


mkdir -p "$WINE_TMP"
cd "$WINE_TMP"


if ! [[ -v OS_ARCH ]]; 
then
    if [[ "$(uname -m)" == "x86_64" ]]; 
    then
        export OS_ARCH="both"
    else
        export OS_ARCH="i386"
    fi
fi

if ! [[ -v WINE_BRANCH ]]; 
then
    export WINE_BRANCH="stable"
fi

if ! [[ -v WINE_VERSION ]]; 
then
    export WINE_VERSION="10.0.0.0"
fi


if ! [[ -v USE_WEB_DOWNLOAD ]];
then
    if [[ "$OS_ARCH" == "i386" ]] || [[ "$OS_ARCH" == "both" ]]; 
    then
        echo ""
        echo "Enabling i386 repository if not available yet ..."

        sudo dpkg --add-architecture i386
    fi
fi


if ! [[ -v USE_WEB_DOWNLOAD ]];
then
    echo ""
    echo "Refreshing APT database ..."
    echo "---------------------------"

    sudo apt update

    if ! [[ "$?" == "0" ]]; 
    then
        abort "Something is wrong with APT. Fix it first."
    fi
fi


if [[ "$OS_ARCH" == "i386" ]] || [[ "$OS_ARCH" == "both" ]]; 
then
    if [[ -f "/tmp/.last_wine32_download" ]];
    then
        rm "/tmp/.last_wine32_download"
    fi
    
    echo ""
    echo "Downloading WINE (32 bit) ($WINE_BRANCH) ($WINE_VERSION) ..."
    echo "-------------------------------------------------------------"

    if ! [[ -v USE_WEB_DOWNLOAD ]];
    then
        WINE_i386_1="wine-${WINE_BRANCH}-i386"
        WINE_i386_1+="=${WINE_VERSION}"
        WINE_i386_1+="~${OS_VERSION}-1"

        WINE_i386_2="wine-${WINE_BRANCH}"
        WINE_i386_2+="=${WINE_VERSION}"
        WINE_i386_2+="~${OS_VERSION}-1"
        #WINE_i386_1="wine-${WINE_BRANCH}:i386"
        #WINE_i386_1+="=${WINE_VERSION}"
        #WINE_i386_1+="~${OS_VERSION}-1"

        #WINE_i386_2="wine-${WINE_BRANCH}-i386"
        #WINE_i386_2+="=${WINE_VERSION}"
        #WINE_i386_2+="~${OS_VERSION}-1"

        if [[ -f "$WINE_TMP/$WINE_i386_1" ]] &&
           [[ -f "$WINE_TMP/$WINE_i386_2" ]];
        then
            echo "Already downloaded. Using the existing files."
        else
            apt download $WINE_i386_1
            apt download $WINE_i386_2
        fi
    else
        WINE_i386_1="wine-${WINE_BRANCH}-i386"
        WINE_i386_1+="_${WINE_VERSION}"
        WINE_i286_1+="~${LATEST_DEBIAN}-1_i386"

        WINE_i386_2+="wine-${WINE_BRANCH}"
        WINE_i386_2+="_${WINE_VERSION}"
        WINE_i386_2+="~${LATEST_DEBIAN}-1_386"
#        WINE_i386_1="wine-${WINE_BRANCH}-i386_${WINE_VERSION}"
#        WINE_i386_1+="~${LATEST_DEBIAN}-1_i386"

#        WINE_i386_2="wine-${WINE_BRANCH}_${WINE_VERSION}"
#        WINE_i386_2+="~${LATEST_DEBIAN}-1_i386"

        if [[ -f "$WINE_TMP/$WINE_i386_1" ]] &&
           [[ -f "$WINE_TMP/$WINE_i386_2" ]];
        then
            echo "Already downloaded. Using the existing files."
        else
            echo "TODO: Web download"
        fi
    fi
fi


if [[ "$OS_ARCH" == "amd64" ]] || [[ "$OS_ARCH" == "both" ]]; 
then
    if [[ -f "/tmp/.last_wine64_download" ]];
    then
        rm "/tmp/.last_wine64_download"
    fi
    
    echo ""
    echo "Downloading WINE (64 bit) ($WINE_BRANCH) ($WINE_VERSION) ..."
    echo "------------------------------------------------------------"

    if ! [[ -v USE_WEB_DOWNLOAD ]];
    then
        WINE_amd64_1="wine-${WINE_BRANCH}-amd64"
        WINE_amd64_1+="=${WINE_VERSION}"
        WINE_amd64_1+="~${OS_VERSION}-1"
        
        WINE_amd64_2="wine-${WINE_BRANCH}"
        WINE_amd64_2+="=${WINE_VERSION}"
        WINE_amd64_2+="~${OS_VERSION}-1"
        #WINE_amd64_1="wine-${WINE_BRANCH}:amd64"
        #WINE_amd64_1+="=${WINE_VERSION}"
        #WINE_amd64_1+="~${OS_VERSION}-1"

        #WINE_amd64_2="wine-${WINE_BRANCH}-amd64"
        #WINE_amd64_2+="=${WINE_VERSION}"
        #WINE_amd64_2+="~${OS_VERSION}-1"

        if [[ -f "$WINE_TMP/$WINE_amd64_1" ]] &&
           [[ -f "$WINE_TMP/$WINE_amd64_2" ]];
        then
            echo "Already downloaded. Using the existing files."
        else
            apt download $WINE_amd64_1
            apt download $WINE_amd64_2
        fi
    else
        WINE_amd64_1="wine-${WINE_BRANCH}-amd64"
        WINE_amd64_1+="_${WINE_VERSION}"
        WINE_amd64_1+="~${LATEST_DEBIAN}-1_amd64"
    
        WINE_amd64_2+="wine-${WINE_BRANCH}"
        WINE_amd64_2+="_${WINE_VERSION}"
        WINE_amd64_2+="~${LATEST_DEBIAN}-1_amd64"
        #WINE_amd64_1="wine-${WINE_BRANCH}-amd64_${WINE_VERSION}"
        #WINE_amd64_1+="~${LATEST_DEBIAN}-1_amd64"

        #WINE_amd64_2="wine-${WINE_BRANCH}_${WINE_VERSION}"
        #WINE_amd64_2+="~${LATEST_DEBIAN}-1_amd64"

        if [[ -f "$WINE_TMP/$WINE_amd64_1" ]] &&
           [[ -f "$WINE_TMP/$WINE_amd64_2" ]];
        then
            echo "Already downloaded. Using the existing files."
        else
            echo "TODO: Web download"
        fi
    fi
fi


echo ""
echo "Extracting WINE ..."
echo "-------------------"

WINE32_DIR="wine-${WINE_VERSION}_i386"
WINE64_DIR="wine-${WINE_VERSION}_amd64"


if [[ "$OS_ARCH" == "i386" ]] || [[ "$OS_ARCH" == "both" ]]; 
then
    ls *_i386.deb > /dev/null

    if ! [[ "$?" == "0" ]]; 
    then
        abort "Failed. WINE i386 packages may have failed downloading..."
    fi

    for package in $(ls *_i386.deb);
    do
        if ! [[ -v USE_WEB_DOWNLOAD ]];
        then
            dpkg-deb -x $package $WINE32_DIR
        else
            mkdir /tmp/debtmp/wine
                        
            ar x $package --output /tmp/debtmp
            
            if [[ "$?" == "0" ]];
            then
                tar xvf /tmp/debtmp/data.tar.xz -C /tmp/debtmp/wine
            
                if [[ "$?" == "0" ]];
                then
                    mv /tmp/debtmp/wine/opt $WINE64_DIR/
                    mv /tmp/debtmp/wine/usr $WINE64_DIR/

                    rm -r /tmp/debtmp
                fi
            fi
        fi
        
        if ! [[ "$?" == "0" ]]; 
        then
            abort "Failed extracting '$package' in '$WINE32_DIR'."
        fi
    done

    echo "$WINE_BRANCH" > "$WINE32_DIR/.wine_branch"
    echo "$WINE_VERSION" > "$WINE32_DIR/.wine_version"
    echo "i386" > "$WINE32_DIR/.wine_arch"

    echo "WINE (32 bit) extracted in $WINE_TMP/$WINE32_DIR."

    echo "$WINE_TMP/$WINE32_DIR" > /tmp/.last_wine32_download
fi


if [[ "$OS_ARCH" == "amd64" ]] || [[ "$OS_ARCH" == "both" ]]; 
then
    ls *_amd64.deb > /dev/null

    if ! [[ "$?" == "0" ]]; 
    then
        abort "Failed. WINE amd64 packages may have failed downloading..."
    fi

    for package in $(ls *_amd64.deb);
    do
        if ! [[ -v USE_WEB_DOWNLOAD ]];
        then
            dpkg-deb -x $package $WINE64_DIR
        else
            mkdir /tmp/debtmp/wine
            
            ar x $package --output /tmp/debtmp

            if [[ "$?" == "0" ]];
            then
                tar xvf /tmp/debtmp/data.tar.xz -C /tmp/debtmp/wine

                if [[ "$?" == "0" ]];
                then
                    mv /tmp/debtmp/wine/opt $WINE64_DIR/
                    mv /tmp/debtmp/wine/usr $WINE64_DIR/

                    rm -r /tmp/debtmp
                fi
            fi
        fi
        
        if ! [[ "$?" == "0" ]]; 
        then
            abort "Failed extracting '$package' in '$WINE64_DIR'."
        fi
    done

    echo "$WINE_BRANCH" > "$WINE64_DIR/.wine_branch"
    echo "$WINE_VERSION" > "$WINE64_DIR/.wine_version"
    echo "amd64" > "$WINE64_DIR/.wine_arch"

    echo "WINE (64 bit) extracted in $WINE_TMP/$WINE64_DIR."

    echo "$WINE_TMP/$WINE64_DIR" > /tmp/.last_wine64_download
fi
