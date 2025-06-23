#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/utils/common.sh

init "[053] Import the cluster continuous deliveries"

find . -type f -name '*.yml' | while read -r file; do
  REASON=`yq '.status.conditions.Ready.reason' $file`
  if [ $REASON == "Enabled" ] || [ $REASON == "Enabling" ]; then
    CLUSTER_NAME=`yq '.fullName.clusterName' $file`
    MGMT_CLUSTER_NAME=`yq '.fullName.managementClusterName' $file`
    PROVISIONER_NAME=`yq '.fullName.provisionerName' $file`
    tanzu tmc continuousdelivery enable -s cluster -m $MGMT_CLUSTER_NAME -p $PROVISIONER_NAME -c $CLUSTER_NAME
  fi
done
