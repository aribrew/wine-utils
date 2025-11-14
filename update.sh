#!/bin/bash


source bash_helpers.sh

if ! [[ -v BASH_HELPERS_LOADED ]];
then
    echo -e "BASH helpers not found in PATH. Install it first.\n"
    exit 1
fi


SCRIPT_HOME=$(realpath $(dirname $0))


echo -e "Trying to update files with Github ..."
echo -e "--------------------------------------"

cd "$SCRIPT_HOME"

git pull


if ! [[ "$?" == "0" ]];
then
    echo -e "Failed syncing with the wine-utils repo."
    echo -e "Current version may be outdated.\n"
fi


"$SCRIPT_HOME/install_winenv.sh"

