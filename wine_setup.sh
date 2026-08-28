#!/bin/bash

SCRIPT_HOME=$(realpath $(dirname $0))

source "$SCRIPT_HOME/wine_helpers"


usage()
{
    echo -e "Usage: \n"
    echo -e "wine_setup.sh"
    echo -e ": Setup the required packages for using WINE."
    echo -e "  Also installs the WINE repository.\n"
}


if [[ "$1" == "" ]] || [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    abort
fi
