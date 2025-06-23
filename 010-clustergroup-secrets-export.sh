#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/utils/common.sh

init "[010] Export the cluster group secrets" "true"

tanzu tmc secret list -s clustergroup -o yaml | yq '.secrets[]' -s '.fullName.clusterGroupName + "_" + .fullName.namespaceName  + "_" + .fullName.name'
