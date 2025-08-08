#!/bin/bash

MC_LIST_FOLDER=data/clusters
ATTACHED_CLUSTER_LIST_FILE=$MC_LIST_FOLDER/attached_clusters.yaml

# Define cluster name filter.
#export CLUSTER_NAME_FILTER="my-cluster,another-cluster"

#Export all the available attached clusters.
echo "Export all the attached clusters"

mkdir -p $MC_LIST_FOLDER && tanzu tmc cluster list -m attached -p attached -o yaml > $ATTACHED_CLUSTER_LIST_FILE

# Further process the file if 'CLUSTER_NAME_FILTER' environment variable is set.
if [[ -n "$CLUSTER_NAME_FILTER" ]]; then
    echo "Filter clusters with filter CLUSTER_NAME_FILTER=$CLUSTER_NAME_FILTER"
    yq -i 'del(.clusters[] | select(.fullName.name as $name | env(CLUSTER_NAME_FILTER) | split(",") as $list | $list | contains([$name]) | not))' $ATTACHED_CLUSTER_LIST_FILE
fi