#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/common.sh

init "[024] Export the cluster kustomizations" "true"

tanzu tmc continuousdelivery ks list -s cluster -o yaml | yq '.kustomizations[]' -s '.fullName.managementClusterName + "_" + .fullName.provisionerName + "_" + .fullName.clusterName + "_" + .fullName.name'
