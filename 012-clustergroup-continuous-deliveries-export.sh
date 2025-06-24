#!/bin/bash
set -eE -o pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source $SCRIPT_DIR/utils/common.sh

init "[012] Export the cluster group continuous deliveries" "true"

tanzu tmc clustergroup list -o yaml | yq '.clusterGroups[].fullName.name' > cluster_groups.txt

while read cg; do
  log debug "curl -s -X GET \"${TMC_ENDPOINT}/v1alpha1/clustergroups/$cg/fluxcd/continuousdelivery\""
  curl -s -X GET "$TMC_ENDPOINT/v1alpha1/clustergroups/$cg/fluxcd/continuousdelivery" -H "Authorization: Bearer $ACCESS_TOKEN" | yq -p json '.continuousDeliveries[0]' > $cg.yml
done < cluster_groups.txt

rm cluster_groups.txt
