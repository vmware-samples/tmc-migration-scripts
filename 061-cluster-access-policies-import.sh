#! /bin/bash

source utils/common.sh
source utils/policy-helper.sh

TEMP_DIR=$(mktemp -d)
SRC_DIR="policies/iam"

ONBOARDED_CLUSTER_INDEX_FILE="clusters/onboarded-clusters-name-index"


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

        jq '.effective[] | select(.spec.inherited != true).spec.policySpec' $resource_full_name.json > $rolebindings

        IFS='_' read -r mgmt prvn name <<< "$resource_full_name"
        if check_onboarded_cluster $mgmt $prvn $name; then
            log info "[SKIP] undesired cluster $mgmt/$prvn/$name"
            continue
        fi
        log info "Importing access policies on cluster $mgmt/$prvn/$name ..."
        import_rolebindings "$rolebindings" "$scope" "$name" "fullName.managementClusterName=$mgmt&fullName.provisionerName=$prvn"
    done
    popd > /dev/null
}

log "************************************************************************"
log "* Import Policy Access on Clusters to TMC SM ..."
log "************************************************************************"

import_cluster_rolebindings