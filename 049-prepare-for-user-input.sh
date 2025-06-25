#!/bin/bash

INPUT_CLUSTERS_FILE=data/clusters/attached_non_npc_clusters.yaml
WC_KUBECONFIG_INDEX_FILE=data/clusters/attached-wc-kubeconfig-index-file
PLACEHOLDER_TEXT="/path/to/the/real/wc_kubeconfig/file"

# Clear index file first
rm -f $WC_KUBECONFIG_INDEX_FILE

# Iterate through clusters
index=0
total=$(yq '.clusters | length' $INPUT_CLUSTERS_FILE)

while [ "$index" -lt "$total" ]; do
  health=$(yq ".clusters[$index].status.health" $INPUT_CLUSTERS_FILE)

  if [ "$health" == "HEALTHY" ]; then
    name=$(yq ".clusters[$index].fullName.name" $INPUT_CLUSTERS_FILE)
    echo "Append cluster $name to $WC_KUBECONFIG_INDEX_FILE"
    echo "$name: $PLACEHOLDER_TEXT" >> "$WC_KUBECONFIG_INDEX_FILE"
  fi

  index=$((index + 1))
done