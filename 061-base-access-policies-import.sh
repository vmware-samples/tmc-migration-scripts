#! /bin/bash

source utils/common.sh
source utils/policy-helper.sh

register_last_words "Import access policies"

DATA_DIR="data"
SRC_DIR="$DATA_DIR/policies/iam"
TEMP_DIR="$PWD/$SRC_DIR/$(date +%s)"

import_org_rolebindings() {
    scope="organization"

    org_temp="$TEMP_DIR/$scope"
    mkdir -p $org_temp

    pushd $SRC_DIR/$scope > /dev/null
    rolebindings="$org_temp/rolebindings.json"
    direct_effectives=$(jq '.policyList[] | length' rolebindings.json)
    if [ $direct_effectives -ne 0 ]; then
        jq '.policyList[0] | del(.meta)' rolebindings.json > $rolebindings
        import_rolebindings "$rolebindings" "$scope"
    fi
    popd > /dev/null
}

import_clustergroup_rolebindings() {
    scope="clustergroups"

    clustergroup_temp="$TEMP_DIR/$scope"
    mkdir -p $clustergroup_temp

    pushd $SRC_DIR/$scope > /dev/null
    ls *.json | sed 's/.json$//'\ | \
    while read -r resource_name
    do
        log info "Importing access policies on clustergroup $resource_name ..."
        
        rolebindings="$clustergroup_temp/$resource_name.json"
        direct_effectives=$(jq '.effective[] | select(.spec.inherited != true)' $resource_name.json)
        if [ -z "$direct_effectives" ]; then
            log info "[SKIP] no direct rolebinding for $scope:$resource_name is required to imported"
            continue
        fi

        jq '.effective[] | select(.spec.inherited != true).spec.policySpec' $resource_name.json > $rolebindings
        
        import_rolebindings "$rolebindings" "$scope" "$resource_name"
    done
    popd > /dev/null
}




import_workspace_rolebindings() {
    scope="workspaces"

    workspace_temp="$TEMP_DIR/$scope"
    mkdir -p $workspace_temp

    pushd $SRC_DIR/$scope > /dev/null
    ls *.json | sed 's/.json$//'\ | \
    while read -r resource_name
    do
        log info "Importing access policies on workspace $resource_name ..."
        
        rolebindings="$workspace_temp/$resource_name.json"
        direct_effectives=$(jq '.effective[] | select(.spec.inherited != true)' $resource_name.json)
        if [ -z "$direct_effectives" ]; then
            log info "[SKIP] no direct rolebinding for $scope:$resource_name is required to imported"
            continue
        fi

        jq '.effective[] | select(.spec.inherited != true).spec.policySpec' $resource_name.json > $rolebindings
        
        import_rolebindings "$rolebindings" "$scope" "$resource_name"
    done
    popd > /dev/null
}

log "************************************************************************"
log "* Import Policy Access to TMC SM ..."
log "************************************************************************"

log info "Importing rolebindings on organization ..."
import_org_rolebindings

log info "Importing rolebindings on clustergroups ..."
import_clustergroup_rolebindings

log info "Importing rolebindings on workspaces ..."
import_workspace_rolebindings