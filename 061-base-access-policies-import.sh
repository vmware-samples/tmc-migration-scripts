#! /bin/bash

source utils/policy-helper.sh

TEMP_DIR=$(mktemp -d)
SRC_DIR="policies/iam"

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

import_namespace_rolebindings() {
    scope="namespaces"

    namespace_temp="$TEMP_DIR/$scope"
    mkdir -p $namespace_temp

    pushd $SRC_DIR/$scope > /dev/null
    ls *.json | sed 's/.json$//'\ | \
    while read -r resource_full_name
    do
        rolebindings="$namespace_temp/$resource_full_name.json"
        direct_effectives=$(jq '.effective[] | select(.spec.inherited != true)' $resource_full_name.json)
        if [ -z "$direct_effectives" ]; then
            log info "[SKIP] no direct rolebinding for $scope:$resource_full_name is required to imported"
            continue
        fi

        jq '.effective[] | select(.spec.inherited != true).spec.policySpec' $resource_full_name.json > $rolebindings

        IFS='_' read -r mgmt prvn cls name <<< "$resource_full_name"
        if ! grep "$mgmt.$prvn.$cls" $ONBOARDED_CLUSTER_INDEX_FILE; then
            log info "[SKIP] undesired namespace $mgmt/$prvn/$cls/$name"
            continue
        fi

        import_rolebindings "$rolebindings" "clusters/$cls/$scope" "$name" "fullName.managementClusterName=$mgmt&fullName.provisionerName=$prvn"
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

log info "Importing rolebindings on namespaces ..."
import_namespace_rolebindings

log info "Importing rolebindings on workspaces ..."
import_workspace_rolebindings