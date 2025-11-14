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


OS_NAME=$(os_name)
OS_VERSION=$(os_version)
LATEST_DEBIAN="trixie"


if [[ "$OS_NAME" == "arch" ]];
then
    echo "ArchLinux detected. You can download WINE BUT ArchLinux does not "
    echo "support 32 bit software, so, you cannot run WINE for i386, and so, "
    echo "32 bit Windows applications will be run unsig WOW64."
    echo ""
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


WINE_BASE_PKG="wine-${WINE_BRANCH}_${WINE_VERSION}~${OS_VERSION}"
WINE_BASE_PKG+="-1_amd64.deb"

WINE_i386_PKG="wine-${WINE_BRANCH}-i386_${WINE_VERSION}~${OS_VERSION}"
WINE_i386_PKG+="-1_i386.deb"

WINE_amd64_PKG="wine-${WINE_BRANCH}-amd64_${WINE_VERSION}~${OS_VERSION}"
WINE_amd64_PKG+="-1_amd64.deb"


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
fi


echo ""
echo "Extracting WINE ..."
echo "-------------------"

WINE32_DIR="wine-${WINE_VERSION}_i386"
WINE64_DIR="wine-${WINE_VERSION}_amd64"


if [[ "$OS_ARCH" == "i386" ]] || [[ "$OS_ARCH" == "both" ]]; 
then
    if ! [[ -f "$WINE_BASE_PKG" ]] || ! [[ -f "$WINE_i386_PKG" ]];
    then
        abort "Failed. WINE i386 packages may have failed downloading..."
    fi

    if ! [[ -v USE_WEB_DOWNLOAD ]];
    then
        dpkg-deb -x $WINE_BASE_PKG $WINE32_DIR
        dpkg-deb -x $WINE_i386_PKG $WINE32_DIR

        if ! [[ "$?" == "0" ]]; 
        then
            abort "Failed extracting WINE (32 bit) in '$WINE32_DIR'."
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
                mv "$WEB_TMP/wine/opt" $WINE32_DIR/
                mv "$WEB_TMP/wine/usr" $WINE32_DIR/

                rm -r "$WEB_TMP"
            fi
        fi
    fi


    echo "$WINE_BRANCH" > "$WINE32_DIR/.wine_branch"
    echo "$WINE_VERSION" > "$WINE32_DIR/.wine_version"
    echo "i386" > "$WINE32_DIR/.wine_arch"

    echo "WINE (32 bit) extracted in $WINE_TMP/$WINE32_DIR."

    echo "$WINE_TMP/$WINE32_DIR" > /tmp/.last_wine32_download
fi


if [[ "$OS_ARCH" == "amd64" ]] || [[ "$OS_ARCH" == "both" ]]; 
then
    if ! [[ -f "$WINE_BASE_PKG" ]] || ! [[ -f "$WINE_amd64_PKG" ]];
    then
        abort "Failed. WINE amd64 packages may have failed downloading..."
    fi

    if ! [[ -v USE_WEB_DOWNLOAD ]];
    then
        dpkg-deb -x $WINE_BASE_PKG $WINE64_DIR
        dpkg-deb -x $WINE_amd64_PKG $WINE64_DIR

        if ! [[ "$?" == "0" ]]; 
        then
            abort "Failed extracting WINE (64 bit) in '$WINE64_DIR'."
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


    echo "$WINE_BRANCH" > "$WINE64_DIR/.wine_branch"
    echo "$WINE_VERSION" > "$WINE64_DIR/.wine_version"
    echo "amd64" > "$WINE64_DIR/.wine_arch"

    echo "WINE (64 bit) extracted in $WINE_TMP/$WINE64_DIR."

    echo "$WINE_TMP/$WINE64_DIR" > /tmp/.last_wine64_download
fi
