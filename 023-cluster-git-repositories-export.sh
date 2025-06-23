#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/common.sh

init "[023] Export the cluster git repositories" "true"

tanzu tmc continuousdelivery gitrepository list -s cluster -o yaml | yq '.gitRepositories[]' -s '.fullName.managementClusterName + "_" + .fullName.provisionerName + "_" + .fullName.clusterName + "_" + .fullName.name'
