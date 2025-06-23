#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/utils/common.sh

init "[020] Export the cluster secret exports" "true"

tanzu tmc secret export list -s cluster -o yaml | yq '.secretExports[]' -s '.fullName.managementClusterName + "_" + .fullName.provisionerName + "_" + .fullName.clusterName + "_" + .fullName.namespaceName  + "_" + .fullName.name'
