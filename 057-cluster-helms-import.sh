#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/common.sh

init "[057] Import the cluster helms"

find . -type f -name '*.yml' | while read -r file; do
  REASON=`yq '.status.conditions.Ready.reason' $file`
  if [ $REASON == "Enabled" ] || [ $REASON == "Enabling" ]; then
    CLUSTER_NAME=`yq '.fullName.clusterName' $file`
    MGMT_CLUSTER_NAME=`yq '.fullName.managementClusterName' $file`
    PROVISIONER_NAME=`yq '.fullName.provisionerName' $file`
    tanzu tmc helm enable -s cluster -m $MGMT_CLUSTER_NAME -p $PROVISIONER_NAME -c $CLUSTER_NAME
  fi
done
