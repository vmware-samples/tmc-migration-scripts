#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/common.sh

init "[056] Import the cluster kustomizations"

find . -type f -name '*.yml' | while read -r file; do
  yq '.meta = {"description": .meta.description, "labels": .meta.labels } | del(.fullName.orgId) | del(.status)' $file | tanzu tmc continuousdelivery ks create -s cluster -f -
done
