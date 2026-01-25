
#!/bin/bash


abort()
{
    MESSAGE=$1

    if ! [[ "$MESSAGE" == "" ]];
    then
        echo "$MESSAGE"
        echo ""
    fi

    if [[ "$0" == "$SHELL" ]];
    then
        return 1
    else
        exit 1
    fi
}


ask_for()
{
    REQUEST=$1

    if ! [[ "$REQUEST" == "" ]];
    then
        read -p "$REQUEST" RESPONSE

        # Many ways to obtain the response
        #
        # - exported  RESPONSE variable
        # - Temporal file
        # - Printed (for reading with $()

        export RESPONSE

        echo "$RESPONSE" > /tmp/.last_request_response

        echo "$RESPONSE"
    fi
}


ask_yn()
{
    QUESTION=$1

    if ! [[ "$QUESTION" == "" ]];
    then
        read -p "$QUESTION (YS/n): " answer

        if [[ "$answer" == "Y" ]] || [[ "$answer" == "S" ]];
        then
            return 0
            
        elif [[ "$answer" == "n" ]];
        then
            return 1
            
        else
            return -1
        fi
    fi
}


check_deps()
{
    PACKAGES="$1"
    
	DEPS=$(sudo apt-cache depends "$PACKAGES")
	
	REQUIRED_DEPS="$DEPS"
	RECOMMENDED_DEPS="$DEPS"

	echo "$REQUIRED_DEPS" | grep -q "  Depends:"

	if [[ "$?" == "0" ]];
	then
	    DEPENDS_STR="Depends:"
	    RECOMMENDED_STR="Recommends:"
	else
	    DEPENDS_STR="Depende:"
	    RECOMMENDED_STR="Recomienda:"
	fi
	
	REQUIRED_DEPS=$(echo "$REQUIRED_DEPS" | grep "  ${DEPENDS_STR}")
	REQUIRED_DEPS=$(echo "$REQUIRED_DEPS" | sed "s/  ${DEPENDS_STR} //g")
	REQUIRED_DEPS=$(echo "$REQUIRED_DEPS" | sed 's/<//g' | sed 's/>//g')

	RECOMMENDED_DEPS=$(echo "$RECOMMENDED_DEPS" | grep "  ${RECOMMENDED_STR}")
	RECOMMENDED_DEPS=$(echo "$RECOMMENDED_DEPS" | sed "s/  ${RECOMMENDED_STR} //g")
	RECOMMENDED_DEPS=$(echo "$RECOMMENDED_DEPS" | sed 's/<//g' | 's/>//g')

	ALL_DEPS="$REQUIRED_DEPS"
	ALL_DEPS+="$RECOMMENDED_DEPS"

    echo "$ALL_DEPS"
}


check_if_admin()
{
    if [[ "$HOME" == "/root" ]];
    then
        export SUPER_USER=1
    fi
}


check_port()
{
    PORT=$1
    
    if [[ "$PORT" == "" ]];
    then
        sudo netstat -nlp | grep ${PORT}
    fi
}


check_script()
{
	SCRIPT=$(realpath $0)

	bash -n "$SCRIPT"
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


dir_empty()
{
	DIR_PATH="$1"

	ITEMS=$(in_dir "$1")

	if [[ "$ITEMS" == "0" ]];
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


in_dir()
{
	DIR_PATH="$1"

	echo $(ls "$DIR_PATH" | wc -l)
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


is_newer()
{
    FILE_1=$1
    FILE_2=$2

    if [[ "$FILE_1" == "" ]] || [[ "$FILE_2" == "" ]];
    then
        abort "Need two file paths to compare."
    fi

    FILE_1=$(realpath "$FILE_1")
    FILE_2=$(realpath "$FILE_2")

    if [[ "$FILE_1" -nt "$FILE_2" ]];
    then
        echo -e "First is newer.\n"
    else
        echo -e "Second is newer\n."
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


same_file()
{
	FIRST_FILE="$1"
	SECOND_FILE="$2"

	if [[ "$FIRST_FILE" == "" ]] || [[ "$SECOND_FILE" == "" ]];
	then
        return -1
        
	elif ! [[ -f "$FIRST_FILE" ]] || ! [[ -f "$SECOND_FILE" ]];
	then
	    return -1
	else
        FIRST_MD5=$(md5sum "$FIRST_FILE" | cut -d ' ' -f 1)
        SECOND_MD5=$(md5sum "$SECOND_FILE" | cut -d ' ' -f 1)

        if [[ "$FIRST_MD5" == "$SECOND_MD5" ]];
        then
            return 0;
        else
            return 1;
        fi
	fi
}


test_ip()
{
    IP_ADDRESS=$1

    if [[ "$IP_ADDRESS" == "" ]];
    then
        abort "IP address cannot be empty."
    fi
    
    echo "Trying conecting to $IP_ADDRESS ..."
    ping -c 1 $IP_ADDRESS >/dev/null
    
    if [[ "$?" == "1" ]];
    then
        echo -e "Cannot reach $IP_ADDRESS.\n"
        exit 1
    else
        echo -e "OK.\n"
    fi
}


uppercase()
{
    if ! [[ "$1" == "" ]];
    then
        echo "$1" | awk '{print toupper($0)}'
    fi
}


helpers_usage()
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
    echo "bash_helpers.sh --cmds"
    echo ": List all available exported commands."
    echo ""
}


if ! [[ -v ZSH_VERSION ]];
then
    export -f abort
    export -f ask_for
    export -f ask_yn
    export -f check_if_admin
    export -f check_port
    export -f check_script
    export -f check_sudo
    export -f dir_empty
    export -f exec_type
    export -f filext
    export -f in_dir
    export -f is_newer
    export -f lowercase
    export -f os_name
    export -f os_version
    export -f pause
    export -f same_file
    export -f test_ip
    export -f uppercase
fi


if ! [[ -v BASH_HELPERS_LOADED ]];
then
    export BASH_HELPERS_LOADED=1
fi


if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    helpers_usage
    abort

elif [[ "$1" == "--cmds" ]];
then
    echo -e "Available cmds:"
    echo -e "---------------"

    CMDS=$(export -f)

    for cmd in "$CMDS";
    do
        CMD_NAME=$(echo "$cmd" | cut -d ' ' -f 3)
        echo "$CMD_NAME"
    done

    echo ""
    
elif [[ "$1" == "--path" ]];
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

    if ! [[ -d "$INSTALL_PATH" ]];
    then
        mkdir -p "$INSTALL_PATH"
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
