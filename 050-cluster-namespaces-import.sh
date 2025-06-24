#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/utils/common.sh

export IGNORE_TANZU_ERROR="AlreadyExists"

init "[050] Import the managed namespaces"

find . -type f -name '*.yml' | while read -r file; do
  set +e
  check_onboarded_cluster_for_yaml $file

  if [ $? -eq 1 ]; then
    set -e
    yq '.spec.attach = true | .meta = {"description": .meta.description, "labels": .meta.labels } | del(.fullName.orgId) | del(.status)' $file | tanzu tmc cluster namespace create -f -
    mark_success "Cluster" "Import" $file
  fi
done
