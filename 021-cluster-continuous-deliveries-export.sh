#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/common.sh

init "[021] Export the cluster continuous deliveries" "true"

tanzu tmc continuousdelivery list -s cluster -o yaml | yq '.continuousDeliveries[]' -s '.fullName.managementClusterName + "_" + .fullName.provisionerName + "_" + .fullName.clusterName'
