#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/common.sh

init "[016] Export the cluster group helms" "true"

tanzu tmc helm list -s clustergroup -o yaml | yq '.helms[]' -s '.fullName.clusterGroupName'
