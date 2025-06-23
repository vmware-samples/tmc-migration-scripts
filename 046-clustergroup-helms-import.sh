#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/common.sh

init "[046] Import the cluster group helms"

find . -type f -name '*.yml' | while read -r file; do
  PHASE=`yq '.status.phase' $file`
  if [ $PHASE == "APPLIED" ]; then
    GROUP_NAME=`yq '.fullName.clusterGroupName' $file`
    tanzu tmc helm enable -s clustergroup -g $GROUP_NAME
  fi
done
