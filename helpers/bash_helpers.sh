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
        echo "$(cat /etc/os-release | grep '^VERSION_CODENAME=' | cut -d '=' -f 2)"
    fi
}


usage()
{
    echo "source bash_helpers.sh"
    echo ": Loads the functions in the current shell."
    echo ""
    echo "bash_helpers.sh --install [--user|path]"
    echo ": Install the helper."
    echo "- If --user, installs in ~/.local/bin"
    echo "- If a path is given, installs in that path."
    echo "- Otherwise installs in /opt/bin"
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
    export -f check_sudo
    export -f exec_type
    export -f filext
    export -f os_name
    export -f os_version
fi


if [[ "$1" == "--install" ]];
then
    SCRIPT=$(realpath $0)
    FILENAME=$(basename "$SCRIPT")

    if ! [[ "$TERMUX_VERSION" == "" ]];
    then
        INSTALL_PATH="$PREFIX/opt/bin"
        PERMS="770"
        
    else
        if [[ "$2" == "--user" ]];
        then
            INSTALL_PATH="$HOME/.local/bin"
            PERMS="770"
            
        elif [[ -d "$2" ]];
        then
            INSTALL_PATH="$2"
            PERMS="775"
            
        else
            INSTALL_PATH="/opt/bin"
            SUDO="sudo"
            PERMS="755"
        fi
    fi
    
    if ! [[ -d "$INSTALL_PATH" ]];
    then
        $SUDO mkdir -p "$INSTALL_PATH"
    fi

    $SUDO cp $SCRIPT $INSTALL_PATH/
    $SUDO chmod $PERMS "$INSTALL_PATH/${FILENAME}"

    if [[ "$?" == "0" ]];
    then
        if ! [[ -f "$HOME/.bashrc" ]] && [[ -v TERMUX_VERSION ]];
        then
            cp "$PREFIX/etc/bash.bashrc" "$HOME/.bashrc"
        fi

        if ! [[ -f "$HOME/.environment" ]];
        then
            touch "$HOME/.environment"
        fi
        
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
