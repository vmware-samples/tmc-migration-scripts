#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/utils/common.sh

init "[019] Export the cluster secrets" "true"

tanzu tmc secret list -s cluster -o yaml | yq '.secrets[]' -s '.fullName.managementClusterName + "_" + .fullName.provisionerName + "_" + .fullName.clusterName + "_" + .fullName.namespaceName  + "_" + .fullName.name'
