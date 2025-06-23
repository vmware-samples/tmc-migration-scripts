#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/common.sh

init "[017] Export the cluster group helm releases" "true"

tanzu tmc helm release list -s clustergroup -o yaml | yq '.releases[]' -s '.fullName.clusterGroupName + "_" + .fullName.name'
