#!/bin/bash

MC_LIST_YAML_FILE=data/clusters/mc_list.yaml
MC_KUBECONFIG_INDEX_FILE=data/clusters/mc-kubeconfig-index-file

PLACEHOLDER_TEXT="/path/to/the/real/mc_kubeconfig/file"

rm -f $MC_KUBECONFIG_INDEX_FILE

# Iterate through clusters
index=0
total=$(yq '.managementClusters | length' $MC_LIST_YAML_FILE)

while [ "$index" -lt "$total" ]; do
  health=$(yq ".managementClusters[$index].status.health" $MC_LIST_YAML_FILE)
  name=$(yq ".managementClusters[$index].fullName.name" $MC_LIST_YAML_FILE)

  if [ "$health" == "HEALTHY" ] && [[ "$name" != "aks" && "$name" != "eks" && "$name" != "attached" ]]; then
    echo "Append management cluster $name to $MC_KUBECONFIG_INDEX_FILE"
    echo "$name: $PLACEHOLDER_TEXT" >> "$MC_KUBECONFIG_INDEX_FILE"
  fi

  index=$((index + 1))
done