#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/utils/common.sh

init "[054] Import the cluster repository credentials"

find . -type f -name '*.yml' | while read -r file; do
  yq '.meta = {"description": .meta.description, "labels": .meta.labels } | del(.fullName.orgId) | del(.status)' $file | tanzu tmc continuousdelivery repositorysecret create -s cluster -f -
done
