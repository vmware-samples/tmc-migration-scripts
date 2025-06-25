#!/bin/bash

INPUT_CLUSTERS_FILE=data/clusters/attached_non_npc_clusters.yaml
WC_KUBECONFIG_INDEX_FILE=data/clusters/attached-wc-kubeconfig-index-file
PLACEHOLDER_TEXT="/path/to/the/real/wc_kubeconfig/file"

# If the $MC_KUBECONFIG_INDEX_FILE file is NOT completely updated, then stop to proceed.
if grep -q "$PLACEHOLDER_TEXT" "$WC_KUBECONFIG_INDEX_FILE"; then
  echo "⚠️  Warning: Placeholder text '$PLACEHOLDER_TEXT' found in $WC_KUBECONFIG_INDEX_FILE. Please replace it."
  exit 1
fi


# Attach non-NPC clusters.
ONBOARDED_CLUSTER_INDEX_FILE="data/clusters/onboarded-clusters-name-index"

ATTACHED_CLUSTER_DIR=data/clusters/attached
mkdir -p $ATTACHED_CLUSTER_DIR

# Iterate through clusters
index=0
total=$(yq '.clusters | length' $INPUT_CLUSTERS_FILE)

while [ "$index" -lt "$total" ]; do
  health=$(yq ".clusters[$index].status.health" $INPUT_CLUSTERS_FILE)

  if [ "$health" == "HEALTHY" ]; then
    orgId=$(yq ".clusters[$index].fullName.orgId" $INPUT_CLUSTERS_FILE)
    name=$(yq ".clusters[$index].fullName.name" $INPUT_CLUSTERS_FILE)

    file="$ATTACHED_CLUSTER_DIR/attached_wc_${orgId}_${name}.yaml"

    # Save cluster data without .status field.
    yq "del(.clusters[$index].status) | .clusters[$index]" $INPUT_CLUSTERS_FILE > "$file"
    # Remove orgId.
    yq -i 'del(.fullName.orgId)' $file

    # Look up the kubeconfig file path from the provided index file
    KUBECONFIG_PATH=$(grep "^$name:" "$WC_KUBECONFIG_INDEX_FILE" | awk '{print $2}')

    # Attach the cluster using cli.
    if [[ -z "$KUBECONFIG_PATH" ]]; then
      echo "No kubeconfig path found for cluster '$name' from '$WC_KUBECONFIG_INDEX_FILE', attaching cluster without kubeconfig."
      echo "Extra attach operations will be needed by following guide on the UI"
      tanzu tmc cluster attach -f $file
    else
      echo "Attaching cluster '$name' with kubeconfig '$KUBECONFIG_PATH'"
      tanzu tmc cluster attach -f "$file" --kubeconfig "$KUBECONFIG_PATH"
    fi
    
    # Record cluster name for resoruce onboarding
    if [ $? -eq 0 ]; then
      if ! grep -qxf "$name" "$ONBOARDED_CLUSTER_INDEX_FILE"; then
        # If it doesn't exist, append it
        echo "attached.attached.$name" >> "$ONBOARDED_CLUSTER_INDEX_FILE"
      fi
    fi
  fi

  index=$((index + 1))
done
