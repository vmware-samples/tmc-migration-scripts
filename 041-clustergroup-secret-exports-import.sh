#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/utils/common.sh

export IGNORE_TANZU_ERROR="AlreadyExists"

init "[041] Import the cluster group secret exports"

find . -type f -name '*.yml' | while read -r file; do
  yq '.meta = {"description": .meta.description, "labels": .meta.labels } | del(.fullName.orgId) | del(.status)' $file | tanzu tmc secret export create -s clustergroup -f -
  mark_success "ClusterGroup" "Import" $file
done
