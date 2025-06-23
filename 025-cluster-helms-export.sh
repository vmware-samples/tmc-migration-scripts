#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/common.sh

init "[025] Export the cluster helms" "true"

tanzu tmc helm list -s cluster -p '*' -m '*' -o yaml | yq '.helms[]' -s '.fullName.managementClusterName + "_" + .fullName.provisionerName + "_" + .fullName.clusterName'
