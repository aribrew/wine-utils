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


# Install a list of packages for the given architecture
install_packages_for_arch()
{
    PACKAGES=$1
    ARCH=$2

    TO_INSTALL=""

    for package in $PACKAGES; do
        if [[ "$OS_NAME" == "fedora" ]]; 
        then
            TO_INSTALL+="${package} "

        elif [[ "$OS_NAME" == "debian" ]]; 
        then
            TO_INSTALL+="${package}:${ARCH} "
        fi
    done

    if [[ "$OS_NAME" == "fedora" ]]; 
    then
        sudo yum
        sudo yum

    elif [[ "$OS_NAME" == "debian" ]]; 
    then
        sudo apt update
        sudo apt install $TO_INSTALL -y
    fi

    if ! [[ "$?" == "0" ]]; 
    then
        echo ""
        abort "One or more packages failed failed installing."
    fi
}




OS_NAME=$(os_name)
OS_VERSION=$(os_version)

THIS_ARCH=$(uname -m)


if [[ "$OS_NAME" == "arch" ]];
then
    echo "ArchLinux detected. It is more recommeded to use Lutris or Steam, "
    echo "or, if you want to use WINE manually, use a Debian 13 container "
    echo "instead."
    echo ""
    echo "If you want to download WINE manually and run it in ArchLinux,"
    echo "install it through pacman. This will also install its dependencies"
    echo "and now you can download and use yours, but remember: ArchLinux"
    echo "does not support running WINE for i386."
    echo ""

    abort "Aborted."
fi


if [[ "$THIS_ARCH" == "x86" ]]; 
then
    THIS_ARCH="i386"

elif [[ "$THIS_ARCH" == "x86_64" ]]; 
then
    THIS_ARCH="amd64"

elif [[ "$THIS_ARCH" == "aarch64" ]]; 
then
    THIS_ARCH="arm64"
fi


if ! [[ -f "/etc/.wine32_deps_installed" ]] &&
   ! [[ -f "/etc/.wine64_deps_installed" ]]; 
then
    echo ""
    echo "Installing WINE dependencies for ${OS_VERSION} ..."
    echo "--------------------------------------------------"

    if [[ "$OS_VERSION" == "bullseye" ]] || [[ "$OS_VERSION" == "bookworm" ]]; 
    then
        DEPS="libasound2 libc6 libglib2.0-0 libgphoto2-6 libgphoto2-port12 "
        DEPS+="libgstreamer-plugins-base1.0-0 libgstreamer1.0-0 libpcap0.8 "
        DEPS+="libpulse0 libsane1 libudev1 libunwind8 libusb-1.0-0 "
        DEPS+="libwayland-client0 libwayland-egl1 libx11-6 libxext6 "
        DEPS+="libxkbcommon0 libxkbregistry0 ocl-icd-libopencl1 "
        DEPS+="libasound2-plugins libncurses6 libncurses5"

    elif [[ "$OS_VERSION" == "trixie" ]]; 
    then
        DEPS="libasound2t64 libc6 libglib2.0-0t64 libgphoto2-6t64 "
        DEPS+="libgphoto2-port12t64 libgstreamer-plugins-base1.0-0 "
        DEPS+="libgstreamer1.0-0 libpcap0.8t64 libpulse0 libsane1 libudev1 "
        DEPS+="libunwind8 libusb-1.0-0 libwayland-client0 libwayland-egl1 "
        DEPS+="libx11-6 libxext6 libxkbcommon0 libxkbregistry0 "
        DEPS+="ocl-icd-libopencl1 libasound2-plugins libncurses6"
    fi

    if ! [[ -v DEPS ]]; 
    then
        abort "I do not know what dependencies $OS_NAME ($OS_VERSION) requires"
    fi

    
    if [[ "$THIS_ARCH" == "arm64" ]]; 
    then
        sudo dpkg --add-architecture armhf
        sudo apt update

        install_packages_for_arch "$DEPS" "armhf"
        sudo touch /etc/.wine32_deps_installed

        install_packages_for_arch "$DEPS" "arm64"
        sudo touch /etc/.wine64_deps_installed

    elif [[ "$THIS_ARCH" == "amd64" ]]; 
    then
        sudo dpkg --add-architecture i386

        install_packages_for_arch "$DEPS" "i386"
        sudo touch /etc/.wine32_deps_installed

        install_packages_for_arch "$DEPS" "amd64"
        sudo touch /etc/.wine64_deps_installed
    fi
fi
