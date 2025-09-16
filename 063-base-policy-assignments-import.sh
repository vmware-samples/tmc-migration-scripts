#! /bin/bash

source utils/log.sh
source utils/policy-helper.sh

register_last_words "Import policy assignments"

DATA_DIR="data"
DIR="$PWD/$DATA_DIR/policies/assignments"
TEMP_DIR="$DIR/$(date +%s)"
INTERVAL=2

import_org_policies() {
    scope="organization"
    policies_temp="$TEMP_DIR/$scope"
    mkdir -p $policies_temp

    pushd $policies_temp > /dev/null
        yq '.policies[]' -s '.fullName.name' $DIR/$scope/policies.yaml
        for p_file in $(ls *.yml)
        do
            yq -i 'del(.fullName.orgId)' $p_file
            tanzu mission-control policy create -s organization -f $p_file
            sleep $INTERVAL
        done
    popd > /dev/null
}

import_clustergroup_policies() {
    scope="clustergroups"
    policies_temp="$TEMP_DIR/$scope"
    mkdir -p $policies_temp

    generate_policy_spec "$scope" "$policies_temp"

    pushd $policies_temp > /dev/null
        for p_file in $(ls *.yaml)
        do
            IFS='_' read -r cg_name policy_name <<< $(echo "$p_file" | sed 's/.yaml$//g')

            yq e -i ".fullName.clusterGroupName = \"$cg_name\"" $p_file
            log info "Importing policies on clustergroup ${cg_name} ..."
            tanzu mission-control policy create -s clustergroup -f $p_file
            sleep $INTERVAL
        done
    popd > /dev/null
}

import_workspace_policies() {
    scope="workspaces"
    policies_temp="$TEMP_DIR/$scope"
    mkdir -p $policies_temp

    generate_policy_spec "$scope" "$policies_temp"

    pushd $policies_temp > /dev/null
        for p_file in $(ls *.yaml)
        do
            IFS='_' read -r ws_name policy_name <<< $(echo "$p_file" | sed 's/.yaml$//g')

            yq e -i ".fullName.workspaceName = \"$ws_name\"" $p_file
            log info "Importing policies on workspace ${ws_name} ..."
            tanzu mission-control policy create -s workspace -f $p_file
            sleep $INTERVAL
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
