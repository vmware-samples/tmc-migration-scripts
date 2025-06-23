#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/utils/common.sh

init "[055] Import the cluster git repositories"

find . -type f -name '*.yml' | while read -r file; do
  set +e
  check_onboarded_cluster_for_yaml $file

  if [ $? -eq 1 ]; then
    set -e
    yq '.meta = {"description": .meta.description, "labels": .meta.labels } | del(.fullName.orgId) | del(.status)' $file | tanzu tmc continuousdelivery gitrepository create -s cluster -f -
  fi
done
