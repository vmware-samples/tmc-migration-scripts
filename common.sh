#!/bin/bash

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

on_exit() {
    if [ $? -eq 0 ]; then
        echo "$* completed successfully!"
    else
        echo "$* exited with an error."
    fi
    popd
}

init () {
    local msg=$1

    local SCRIPT_DIR="$( cd "$( dirname "$0" )" &> /dev/null && pwd )"
    local SCRIPT_FILE=$(basename "$0")

    echo "$msg ..."

    local N=`echo ${SCRIPT_FILE%.sh} | awk -F- '{print NF-1}'`
    local DIR=$SCRIPT_DIR/data/`echo ${SCRIPT_FILE%.sh} | cut -d - -f 2-$N`

    mkdir -p $DIR
    if [ "$#" -ge 2 ]; then
        rm -rf $DIR/*
    fi

    pushd $DIR

    trap "on_exit $msg" EXIT
}
