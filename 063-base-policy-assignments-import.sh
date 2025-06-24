#! /bin/bash

source utils/policy-helper.sh

TEMP_DIR=$(mktemp -d)
log info "Temporary output in $TEMP_DIR"

SRC_DIR="policies/assignments"

import_org_policies() {
    scope="organization"
    policies_temp="$TEMP_DIR/$scope"
    mkdir -p $policies_temp
    script_path=$PWD
    pushd $policies_temp > /dev/null
        yq '.policies[]' -s '.fullName.name' $script_path/$SRC_DIR/$scope/policies.yaml
        for p_file in $(ls *.yml)
        do
            tanzu mission-control policy create -s organization -f $p_file
        done
    popd > /dev/null
}

import_clustergroup_policies() {
    scope="clustergroups"
    policies_temp="$TEMP_DIR/$scope"
    mkdir -p $policies_temp

    generate_policy_spec "$scope" "$name" "$policies_temp"

    pushd $policies_temp > /dev/null
        for p_file in $(ls *.yaml)
        do
            cg_name=$(echo "$p_file" | sed 's/.yaml$//g')

            yq e -i ".fullName.clusterGroupName = \"$cg_name\"" $p_file
            log info "Importing policies on clustergroup ${cg_name} ..."
            tanzu mission-control policy create -s clustergroup -f $p_file
        done
    popd > /dev/null
}

import_workspace_policies() {
    scope="workspaces"
    policies_temp="$TEMP_DIR/$scope"
    mkdir -p $policies_temp

    generate_policy_spec "$scope" "$name" "$policies_temp"

    pushd $policies_temp > /dev/null
        for p_file in $(ls *.yaml)
        do
            ws_name=$(echo "$p_file" | sed 's/.yaml$//g')

            yq e -i ".fullName.workspaceName = \"$ws_name\"" $p_file
            log info "Importing policies on workspace ${ws_name} ..."
            tanzu mission-control policy create -s workspace -f $p_file
        done
    popd > /dev/null
}

log "************************************************************************"
log "* Import Policy Assignments to TMC SM ..."
log "************************************************************************"

log info "Importing policies on organization ..."
import_org_policies

log info "Importing policies on clustergroups ..."
import_clustergroup_policies

log info "Importing policies on workspaces ..."
import_workspace_policies