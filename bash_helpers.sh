#!/bin/bash


abort()
{
    MESSAGE=$1

    if ! [[ "$MESSAGE" == "" ]];
    then
        echo "$MESSAGE"
        echo ""
    fi

    exit 1
}


check_if_admin()
{
    if [[ "$HOME" == "/root" ]];
    then
        export SUPER_USER=1
    fi
}


check_sudo()
{
    if [[ "$EUID" == "0" ]];
    then
        return 0
    else
        return 1
    fi
}


exec_type()
{
    EXEC=$1
    FILE_TYPE=$(file -L "$EXEC")

    echo ${FILE_TYPE} | grep "ELF 32-bit" > /dev/null

    if [[ "$?" == "0" ]];
    then
        echo "linux-i386"
        echo ""
    else
        echo ${FILE_TYPE} | grep "ELF 64-bit" > /dev/null

        if [[ "$?" == "0" ]];
        then
            echo "linux-amd64"
            echo ""
        else
            echo ${FILE_TYPE} | grep "PE32 executable" > /dev/null

            if [[ "$?" == "0" ]];
            then
                echo "windows-i386"
                echo ""
            else
                echo ${FILE_TYPE} | grep "PE32+ executable" > /dev/null

                if [[ "$?" == "0" ]];
                then
                    echo "windows-amd64"
                    echo ""
                fi
            fi
        fi
    fi
}


filext()
{
    FULL_PATH=$1

    FILE_NAME=$(basename "$FULL_PATH")
    FILE_EXTENSION=${FILE_NAME##*.}

    echo .$FILE_EXTENSION
}


installed()
{
    HELPERS_PATH=$(path)

    if [[ -f "$HELPERS_PATH" ]];
    then
        echo "Helpers installed"
    else
        echo "Helpers not found"
    fi
}


lowercase()
{
    if ! [[ "$1" == "" ]];
    then
        echo "$1" | awk '{print tolower($0)}'
    fi
}


os_name()
{
    echo "$(cat /etc/os-release | grep '^ID=' | cut -d '=' -f 2)"
}


os_version()
{
    if [[ "$(os_name)" == "manjaro" ]];
    then
        echo "rolling"
    else
        OS_INFO=$(cat /etc/os-release)
        OS_VERSION=$(echo "$OS_INFO" | grep '^VERSION_CODENAME=')
        
        echo "$OS_VERSION" | cut -d '=' -f 2 
    fi
}


path()
{
    if ! [[ "$TERMUX_VERSION" == "" ]];
    then
        echo "$PREFIX/opt/bin/bash_helpers.sh"
        
    else
        if [[ "$HOME" == "/root" ]];
        then
            echo "/opt/bin/bash_helpers.sh"
            
        else
            echo "$HOME/.local/bin/bash_helpers.sh"
        fi
    fi
}


pause()
{
    read -p "Press ENTER to continue. Ctrl-C to abort."
}


uppercase()
{
    if ! [[ "$1" == "" ]];
    then
        echo "$1" | awk '{print toupper($0)}'
    fi
}


usage()
{
    echo "source bash_helpers.sh"
    echo ": Loads the functions in the current shell."
    echo ""
    echo "bash_helpers.sh --install"
    echo ": Installs the helpers."
    echo "  - If NOT using sudo, installs in ~/.local/bin"
    echo "  - Otherwise installs in /opt/bin"
    echo ""
    echo "bash_helpers.sh --path"
    echo ": Tells where the helpers are/would be installed."
    echo ""
}




if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    abort
fi


if ! [[ -v ZSH_VERSION ]];
then
    export -f abort
    export -f check_if_admin
    export -f check_sudo
    export -f exec_type
    export -f filext
    export -f lowercase
    export -f os_name
    export -f os_version
    export -f pause
    export -f uppercase
fi


export BASH_HELPERS_LOADED=1


if [[ "$1" == "--path" ]];
then
    path
    
elif [[ "$1" == "--install" ]];
then
    if ! [[ -f "$HOME/.bashrc" ]] && [[ -v TERMUX_VERSION ]];
    then
        cp "$PREFIX/etc/bash.bashrc" "$HOME/.bashrc"
    fi

    if ! [[ -f "$HOME/.environment" ]];
    then
        touch "$HOME/.environment"
    fi
        
    SCRIPT=$(realpath $0)
    FILENAME=$(basename "$SCRIPT")

    INSTALL_PATH=$(dirname $(path))

    if [[ -v SUPER_USER ]];
    then
        PERMS="755"
        SUDO="sudo"
    else
        PERMS="770"
    fi


    $SUDO cp $SCRIPT $INSTALL_PATH/
    $SUDO chmod $PERMS "$INSTALL_PATH/${FILENAME}"

    if [[ "$?" == "0" ]];
    then
        grep -q "$INSTALL_PATH" "$HOME/.environment"

        if ! [[ "$?" == "0" ]];
        then
            echo "export PATH=$INSTALL_PATH:\$PATH" >> "$HOME/.environment"

            grep -q "\$HOME/.environment" "$HOME/.bashrc"

            if [[ "$?" == "1" ]];
            then
                echo "source \$HOME/.environment" >> "$HOME/.bashrc"
            fi
        fi
        
        echo "Bash helpers installed to $INSTALL_PATH."
        echo ""
    fi
fi
