#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/common.sh

init "[026] Export the cluster helm releases" "true"

tanzu tmc helm release list -s cluster -p '*' -m '*' -o yaml | yq '.releases[]' -s '.fullName.managementClusterName + "_" + .fullName.provisionerName + "_" + .fullName.clusterName + "_" + .fullName.name'
