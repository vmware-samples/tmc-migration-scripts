#!/bin/bash

source $(dirname "${BASH_SOURCE[0]}")/log.sh

SCRIPT_DIR="$(dirname "$(readlink -f $0)")"
SCRIPT_FILE="$(basename "$0")"

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

data_dir () {
    local N=`echo ${SCRIPT_FILE%.sh} | awk -F- '{print NF-1}'`
    local DIR=$SCRIPT_DIR/data/`echo ${SCRIPT_FILE%.sh} | cut -d - -f 2-$N`
    mkdir -p $DIR
    echo $DIR
}

init () {
    local msg=$1
    log info "$msg ..."
    log debug "Script $0 directory is $SCRIPT_DIR"

    local DATA_DIR=$(data_dir)

    if [ "$#" -ge 2 ]; then
        log debug "Cleanup directory $DATA_DIR"
        rm -rf $DATA_DIR/*
    fi

    pushd $DATA_DIR

    trap "on_exit $msg" EXIT
}

ONBOARDED_CLUSTER_INDEX_FILE="$(dirname "${BASH_SOURCE[0]}")/../data/clusters/onboarded-clusters-name-index"

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
    if [[ "$owner" == "ClusterGroup" ]]; then
        local CG_NAME=`yq .fullName.clusterGroupName $file`
        local NAME=`yq '.fullName.name // ""' $file`
        local NAMESPACE=`yq '.fullName.namespaceName // ""' $file`
        local RESOURCE=`yq '.type.kind | downcase' $file`

        if [[ -n "$NAME" ]]; then
            RESOURCE="${RESOURCE} '${NAME}'"
        fi

        if [[ -n "$NAMESPACE" ]]; then
            log info "${action} ${RESOURCE} in namespace '${NAMESPACE}' to cluster group '${CG_NAME}' successfully"
        else
            log info "${action} ${RESOURCE} to cluster group '${CG_NAME}' successfully"
        fi
    fi
}

tanzu () {
    log debug "tanzu $@"
    if [[ -n "$IGNORE_TANZU_ERROR" ]]; then
        set +e
        command tanzu "$@" &> tanzu-output.txt
        local EXIT=$?
        if grep "$IGNORE_TANZU_ERROR" tanzu-output.txt &> /dev/null; then
            log debug "Ignore tanzu error [$(cat tanzu-output.txt)]"
            EXIT=0
        fi
        set -e
        if [ $EXIT -ne 0 ]; then
            cat tanzu-output.txt
        fi
        rm -rf tanzu-output.txt
        return $EXIT
    else
        command tanzu "$@"
    fi
}

yq () {
    log debug "yq $@"
    command yq "$@"
}
