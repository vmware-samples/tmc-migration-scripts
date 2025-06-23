#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/utils/common.sh

init "[015] Export the cluster group kustomizations" "true"

tanzu tmc continuousdelivery ks list -s clustergroup -o yaml | yq '.kustomizations[]' -s '.fullName.clusterGroupName + "_" + .fullName.name'
