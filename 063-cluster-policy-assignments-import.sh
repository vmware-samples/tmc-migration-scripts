#! /bin/bash

source utils/common.sh
source utils/policy-helper.sh

register_last_words "Import policy assignments"

DATA_DIR="data"
SRC_DIR="$PWD/$DATA_DIR/policies/assignments"
TEMP_DIR="$SRC_DIR/$(date +%s)"

import_cluster_policies() {
    scope="clusters"
    policies_temp="$TEMP_DIR/$scope"
    mkdir -p $policies_temp

    generate_policy_spec "$scope" "$name" "$policies_temp"

    pushd $policies_temp > /dev/null
        for p_file in $(ls *.yaml)
        do
            cls_full_name=$(echo "$p_file" | sed 's/.yaml$//g')

            IFS='_' read -r mgmt prvn cls <<< "$cls_full_name"

            if ! check_onboarded_cluster $mgmt $prvn $cls; then
                log info "[SKIP] undesired cluster $mgmt/$prvn/$name"
                continue
            fi

            yq e -i ".fullName.managementClusterName = \"$mgmt\" | .fullName.provisionerName = \"$prvn\" | .fullName.clusterName = \"$cls\"" $p_file

            log info "Importing policy assignment on cluster $mgmt/$prvn/$cls ..." 
            tanzu mission-control policy create -s cluster -f $p_file
        done
    popd > /dev/null
}

log "************************************************************************"
log "* Import Policy Assignments on Clusters to TMC SM ..."
log "************************************************************************"

import_cluster_policies