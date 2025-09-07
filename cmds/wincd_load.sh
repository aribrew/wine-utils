#!/bin/bash

if [[ -v WIN_D ]];
then
    if ! [[ "$1" == "" ]] && [[ -d "$1" ]];
    then
        echo -e "TODO\n"
    fi
fi
