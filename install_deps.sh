#!/bin/bash

#########################################################
# Helper for installing WINE and Winetricks dependencies
#########################################################

BASH_HELPERS="/opt/bin/bash_helpers.sh"
SCRIPTS=$(realpath $(dirname $0))


if ! [[ -f "$BASH_HELPERS" ]] &&
     [[ -f "$SCRIPTS/helpers/bash_helpers.sh" ]]; 
then
    "$SCRIPTS/helpers/bash_helpers.sh" --install
fi


if ! [[ -f "$BASH_HELPERS" ]]; 
then
    echo "Cannot find '$BASH_HELPERS'."
    echo ""

    exit 1
    
else
    source "$BASH_HELPERS"
fi


OS_NAME=$(os_name)
THIS_ARCH=$(uname -m)

if [[ "$THIS_ARCH" == "x86" ]];
then
    THIS_ARCH="i386"
    ARCH_IS_32BIT=1

elif [[ "$THIS_ARCH" == "x86_64" ]];
then
    THIS_ARCH="amd64"

elif [[ "$THIS_ARCH" == "aarch64" ]];
then
    THIS_ARCH="arm64"

elif [[ $THIS_ARCH == arm* ]]
then
    THIS_ARCH="armhf"
    ARCH_IS_32BIT=1
else
    abort "Unsupported architecture '$THIS_ARCH'"
fi


if [[ "$OS_NAME" == "arch" ]];
then
    echo "ArchLinux detected."
    echo ""
    echo "Keep in mind that this distro does not support running"
    echo "WINE 32 bit version (wine). Instead, all 32 bit software"
    echo "is executed using the 64 bit version of WINE (wine64) making use"
    echo "of WOW64 (the same thing the real Windows uses when you execute"
    echo "32 bit programs in a 64 bit OS)."
    echo ""
    echo "This means that these 32 bit apps may show problems compared when"
    echo "you run them with a pure 32 bit WINE installation."
    echo ""

    read -p "Press ENTER to continue. Ctrl-C to abort."
fi


echo ""
echo "In a x86 Linux system, this script installs the required dependencies"
echo "for WINE installing the wine-stable and wine-stable-{arch} packages."
echo "Once this is done, these packages are removed leaving the dependencies"
echo "installed. This is the most simple method to achieve this."
echo ""
echo "In ARM we need a different approach: WINE is only for i386/amd64."
echo "This means that you need Box86 and Box64 packages in order to run it,"
echo "and this requires installing WINE dependencies, but for ARM."
echo ""
echo "Because we cannot install them automatically with the package manager,"
echo "we need to ask it about the packages required for the x86 version,"
echo "extract their names and install them for ARM."
echo ""

read -p "Press ENTER to continue. Ctrl-C to abort."


echo ""
echo "Preparing to install required dependencies for WINE ..."
echo "-------------------------------------------------------"


if [[ -v ARCH_IS_32BIT ]];
then
    PACKAGES="wine-stable"
else
    PACKAGES="wine-stable wine-stable-amd64 wine-stable-i386"
fi


if ! [[ "$THIS_ARCH" == "armhf" ]] && ! [[ "$THIS_ARCH" == "arm64" ]];
then
    if [[ "$OS_NAME" == "debian" ]];
    then
        sudo apt install --install-recommends -y $PACKAGES
    fi

    if ! [[ "$?" == "0" ]];
    then
        abort "Failed."
    else
        if [[ "$OS_NAME" == "debian" ]];
        then
            sudo apt install remove -y $PACKAGES
        fi
    fi
else
    if [[ "$OS_NAME" == "debian" ]];
    then
        REQUIRED_DEPS=$(sudo apt-cache depends wine-stable-amd64)

        echo "$REQUIRED_DEPS" | grep -q "  Depends:"

        if [[ "$?" == "0" ]];
        then
            DEPENDS_STR="Depends:"
        else
            DEPENDS_STR="Depende:"
        fi
        
        REQUIRED_DEPS=$(echo "$REQUIRED_DEPS" | grep "  ${DEPENDS_STR}")
        REQUIRED_DEPS=$(echo "$REQUIRED_DEPS" | sed "s/  ${DEPENDS_STR} //g")
        REQUIRED_DEPS=$(echo "$REQUIRED_DEPS" | sed 's/<//g')
        REQUIRED_DEPS=$(echo "$REQUIRED_DEPS" | sed 's/>//g')

        touch /tmp/packages_to_install

        for package in $REQUIRED_DEPS;
        do
            # Remove package default architecture from name
            package=$(echo "$package" | sed 's/:amd64//g')

            echo -n "${package}:${THIS_ARCH} " >> /tmp/packages_to_install

            if [[ "$THIS_ARCH" == "arm64" ]];
            then
                echo -n "${package}:armhf" >> /tmp/packages_to_install
            fi
        done

        sudo apt install $(cat /tmp/packages_to_install)
    fi
fi


echo ""
echo "Done."
echo ""
