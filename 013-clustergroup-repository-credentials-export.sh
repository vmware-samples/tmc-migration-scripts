#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/common.sh

init "[013] Export the cluster group repository credentials" "true"

tanzu tmc continuousdelivery repositorysecret list -s clustergroup -o yaml | yq '.sourceSecrets[]' -s '.fullName.clusterGroupName + "_" + .fullName.name'
