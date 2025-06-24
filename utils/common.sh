#!/bin/bash

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

source $SCRIPT_DIR/log.sh

pushd () {
    command pushd "$@" > /dev/null
}

popd () {
    command popd "$@" > /dev/null
}

on_exit() {
    if [ $? -eq 0 ]; then
        log info "$* completed successfully! ${COLOR_SUCCESS}✔${COLOR_RESET}"
    else
        log error "$* exited with an error. ${COLOR_ERROR}✖${COLOR_RESET}"
    fi
    popd
}

init () {
    local msg=$1

    local SCRIPT_DIR="$( cd "$( dirname "$0" )" &> /dev/null && pwd )"
    local SCRIPT_FILE=$(basename "$0")

    log info "$msg ..."

    local N=`echo ${SCRIPT_FILE%.sh} | awk -F- '{print NF-1}'`
    local DIR=$SCRIPT_DIR/data/`echo ${SCRIPT_FILE%.sh} | cut -d - -f 2-$N`

    mkdir -p $DIR
    if [ "$#" -ge 2 ]; then
        log debug "Cleanup directory $DIR"
        rm -rf $DIR/*
    fi

    pushd $DIR

    trap "on_exit $msg" EXIT
}

ONBOARDED_CLUSTER_INDEX_FILE="$SCRIPT_DIR/../clusters/onboarded-clusters-name-index"

check_onboarded_cluster () {
    local onboarded=1
    if ! grep "^$1.$2.$3$" $ONBOARDED_CLUSTER_INDEX_FILE &> /dev/null; then
        log debug "Cluster $1:$2:$3 is not onboarded"
        onboarded=0
    fi
    return $onboarded
}

check_onboarded_cluster_for_yaml () {
    local file=$1
    local MGMT_CLUSTER_NAME=`yq .fullName.managementClusterName $file`
    local PROVISIONER_NAME=`yq .fullName.provisionerName $file`
    local CLUSTER_NAME=`yq .fullName.clusterName $file`
    check_onboarded_cluster $MGMT_CLUSTER_NAME $PROVISIONER_NAME $CLUSTER_NAME
    return $?
}

mark_success () {
    local owner=$1
    local action=$2
    local file=$3

    if [[ "$owner" == "Cluster" ]]; then
        local MGMT_CLUSTER_NAME=`yq .fullName.managementClusterName $file`
        local PROVISIONER_NAME=`yq .fullName.provisionerName $file`
        local CLUSTER_NAME=`yq .fullName.clusterName $file`
        local NAME=`yq '.fullName.name // ""' $file`
        local RESOURCE=`yq '.type.kind | downcase' $file`
        if [[ -n "$NAME" ]]; then
            RESOURCE="${RESOURCE} '${NAME}'"
        fi
        log info "${action} ${RESOURCE} to cluster '${MGMT_CLUSTER_NAME}:${PROVISIONER_NAME}${CLUSTER_NAME}' successfully"
    fi
}

tanzu () {
    set +e
    command tanzu "$@" &> tanzu-output.txt
    local EXIT=$?
    if [[ -n "$IGNORE_TANZU_ERROR" ]]; then
        if grep "$IGNORE_TANZU_ERROR" tanzu-output.txt &> /dev/null; then
            log debug "Ignore tanzu error [$(cat tanzu-output.txt)]"
            EXIT=0
        fi
    fi
    set -e
    if [ $EXIT -ne 0 ]; then
        cat tanzu-output.txt
    fi
    rm -rf tanzu-output.txt
    return $EXIT
}