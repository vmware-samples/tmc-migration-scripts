#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/utils/common.sh

init "[011] Export the cluster group secret exports" "true"

tanzu tmc secret export list -s clustergroup -o yaml | yq '.secretExports[]' -s '.fullName.clusterGroupName + "_" + .fullName.namespaceName  + "_" + .fullName.name'
