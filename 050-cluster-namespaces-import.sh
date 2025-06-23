#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/utils/common.sh

init "[050] Import the managed namespaces"

find . -type f -name '*.yml' | while read -r file; do
    yq '.spec.attach = true | .meta = {"description": .meta.description, "labels": .meta.labels } | del(.fullName.orgId) | del(.status)' $file | tanzu tmc cluster namespace create -f -
done
