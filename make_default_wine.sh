#!/bin/bash

WINE_PATH=$(realpath $(dirname $0))


usage()
{
    echo -e "Usage: make_default.sh"
    echo -e ""
    echo -e "This script is meant to be part of a WINE installation."
    echo -e "When placed in the its top level (named 'make_default.sh'),"
    echo -e "that WINE copy is set as the default one when working with"
    echo -e "the rest of the WINE Utils package."
    echo -e ""
}


if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]];
then
    usage
    exit 1
fi


if ! [[ "$WINE_PATH/.wine_version" ]];
then
    echo -e "This script only works at the root of a WINE tree.\n"
    exit 1
fi


echo "$WINE_PATH" > "$HOME/.default_wine"

echo -e "Now '$WINE_PATH' is the default WINE to use"
echo -e "with the WINE Utils package.\n"
