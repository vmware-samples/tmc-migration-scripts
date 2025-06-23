#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/utils/common.sh

init "[014] Export the cluster group git repositories" "true"

tanzu tmc continuousdelivery gitrepository list -s clustergroup -o yaml | yq '.gitRepositories[]' -s '.fullName.clusterGroupName + "_" + .fullName.name'
