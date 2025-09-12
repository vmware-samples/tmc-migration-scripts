#! /bin/bash

source utils/policy-helper.sh
source utils/common.sh

register_last_words "Import access policies"

DATA_DIR="data"
SRC_DIR="$DATA_DIR/policies/iam"
TEMP_DIR="$PWD/$SRC_DIR/$(date +%s)"
INTERVAL=2

import_cluster_rolebindings() {
    scope="clusters"

    cluster_temp="$TEMP_DIR/$scope"
    mkdir -p $cluster_temp

    pushd $SRC_DIR/$scope > /dev/null
    ls *.json | sed 's/.json$//' | \
    while read -r resource_full_name
    do
        rolebindings="$cluster_temp/$resource_full_name.json"
        direct_effectives=$(jq '.effective[] | select(.spec.inherited != true)' $resource_full_name.json)
        if [ -z "$direct_effectives" ]; then
            log info "[SKIP] no direct rolebinding for $scope:$resource_full_name is required to imported"
            continue
        fi

        jq '.effective[] | select(.spec.inherited != true).spec.policySpec' $resource_full_name.json | update_default_group > $rolebindings

        IFS='_' read -r mgmt prvn name <<< "$resource_full_name"
        if ! check_onboarded_cluster $mgmt $prvn $name; then
            log info "[SKIP] undesired cluster $mgmt/$prvn/$name"
            continue
        fi
        log info "Importing access policies on cluster $mgmt/$prvn/$name ..."
        import_rolebindings "$rolebindings" "$scope" "$name" "fullName.managementClusterName=$mgmt&fullName.provisionerName=$prvn"
        sleep $INTERVAL
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

        jq '.effective[] | select(.spec.inherited != true).spec.policySpec' $resource_full_name.json | update_default_group > $rolebindings

        IFS='_' read -r mgmt prvn cls name <<< "$resource_full_name"
        if ! check_onboarded_cluster $mgmt $prvn $cls; then
            log info "[SKIP] undesired namespace $mgmt/$prvn/$cls/$name"
            continue
        fi
        import_rolebindings "$rolebindings" "clusters/$cls/$scope" "$name" "fullName.managementClusterName=$mgmt&fullName.provisionerName=$prvn"
        sleep $INTERVAL
    done
    popd > /dev/null
}

log "************************************************************************"
log "* Import Policy Access on Clusters and Namespaces to TMC SM ..."
log "************************************************************************"

log info "Importing rolebindings on clusters ..."
import_cluster_rolebindings

log info "Importing rolebindings on namespaces ..."
import_namespace_rolebindings
