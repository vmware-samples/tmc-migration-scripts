#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/utils/common.sh
source $SCRIPT_DIR/utils/offboard-clusters.sh

init "[022] Export the cluster repository credentials" "true"

if [ -z "${TMC_MC_FILTER}" ] && [ -z "${CLUSTER_NAME_FILTER}" ]; then
    log error "Please set env 'TMC_MC_FILTER' or 'CLUSTER_NAME_FILTER'"
    exit 1
fi

OFFBOARD_CLUSTERS=$(download_offboard_clusters)

while IFS=$'\t' read -r mgmt prvn name
do
    # skip empty data
    if [ -z $name ]; then
        continue
    fi
    log info "Export repository credentials of cluster ${mgmt}:${prvn}:$name"
    tanzu tmc continuousdelivery repositorysecret list -s cluster  -m $mgmt -p $prvn --cluster-name $name -o yaml | \
    yq '.sourceSecrets[]' -s '.fullName.managementClusterName + "_" + .fullName.provisionerName + "_" + .fullName.clusterName + "_" + .fullName.name'
done <<< "$OFFBOARD_CLUSTERS"
