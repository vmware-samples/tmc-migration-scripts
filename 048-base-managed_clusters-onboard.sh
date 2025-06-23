#!/bin/bash

MC_LIST_YAML_FILE=clusters/mc_list.yaml
MC_KUBECONFIG_INDEX_FILE=clusters/mc-kubeconfig-index-file

# Iterate through clusters
index=0
total=$(yq '.managementClusters | length' $MC_LIST_YAML_FILE)

while [ "$index" -lt "$total" ]; do
  health=$(yq ".managementClusters[$index].status.health" $MC_LIST_YAML_FILE)
  name=$(yq ".managementClusters[$index].fullName.name" $MC_LIST_YAML_FILE)

  if [ "$health" == "HEALTHY" ] && [[ "$name" != "aks" && "$name" != "eks" && "$name" != "attached" ]]; then
    echo "Append management cluster $name to $MC_KUBECONFIG_INDEX_FILE"
    echo "$name: /path/to/the/real/mc_kubeconfig/file" >> "$MC_KUBECONFIG_INDEX_FILE"
  fi

  index=$((index + 1))
done


# Admin kubeconfig index file to get the real admin kubeconfig of management clusters for registration processes.
KUBECONFIG_INDEX_FILE=clusters/mc-kubeconfig-index-file
# The management cluster list exported before.
MC_LIST_YAML_FILE=clusters/mc_list.yaml

REGISTERED_FILE="clusters/mc_registered.txt"D
# Reset tracking file
: > "$REGISTERED_FILE"

# Iterate through clusters
index=0
total=$(yq '.managementClusters | length' $MC_LIST_YAML_FILE)

# Remove orgId first
yq -i '(.managementClusters[] | .fullName) |= del(.orgId)' $MC_LIST_YAML_FILE

while [ "$index" -lt "$total" ]; do
  health=$(yq ".managementClusters[$index].status.health" $MC_LIST_YAML_FILE)
  name=$(yq ".managementClusters[$index].fullName.name" $MC_LIST_YAML_FILE)

  if [ "$health" == "HEALTHY" ] && [[ "$name" != "aks" && "$name" != "eks" && "$name" != "attached" ]]; then
    orgId=$(yq ".managementClusters[$index].fullName.orgId" $MC_LIST_YAML_FILE)
    file="mc_${orgId}_${name}.yaml"

    # Save cluster data without .status field.
    yq "del(.managementClusters[$index].status) | .managementClusters[$index]" $MC_LIST_YAML_FILE > "$file"

    # Look up the kubeconfig file path from the provided index file
    KUBECONFIG_PATH=$(grep "^$name:" "$KUBECONFIG_INDEX_FILE" | awk '{print $2}')

    # Register the cluster using cli.
    if tanzu tmc mc get "$name" >/dev/null 2>&1; then
      tanzu tmc mc reregister "$name" --kubeconfig "$KUBECONFIG_PATH"
    else
      tanzu tmc mc register "$name" -f "$file" --kubeconfig "$KUBECONFIG_PATH"
    fi
    
    # Track the name of succesfully registered management cluster for later use.
    echo "$name" >> "$REGISTERED_FILE"
  fi

  index=$((index + 1))
done

# Mange the workload clusters.
MIN_VERSION="1.28.0"
ONBOARDED_CLUSTER_INDEX_FILE="clusters/onboared-clusters-name-index"

# Strip v prefix and metadata from version (e.g., v1.29.4+ -> 1.29.4)
sanitize_version() {
  echo "$1" | sed -E 's/^v//' | cut -d'+' -f1
}

compare_versions() {
  # Returns 0 if $1 >= $2
  [ "$(printf "%s\n%s" "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

# Read management cluster name from clusters/mc_registered.txt
while IFS= read -r mc_name; do
    wc_file="clusters/wc_of_${mc_name}.yaml"
    
    if [[ ! -f "$wc_file" ]]; then
        echo "File $wc_file not found. Skipping..."
        continue
    fi

    # Remove orgId first
    yq -i '(.clusters[] | .fullName) |= del(.orgId)' "$wc_file"

    # Count how many workload clusters exist in the file
    cluster_count=$(yq eval '.clusters | length' "$wc_file")

    for i in $(seq 0 $((cluster_count - 1))); do
        version=$(yq eval ".clusters[$i].spec.topology.version" "$wc_file")
        if ! compare_versions "$clean_version" "$MIN_VERSION"; then
          echo "Skipping: $version is NOT supported (< v$MIN_VERSION)"
        fi
        name=$(yq eval ".clusters[$i].fullName.name" "$wc_file")
        mgmt=$(yq eval ".clusters[$i].fullName.managementClusterName" "$wc_file")
        prov=$(yq eval ".clusters[$i].fullName.provisionerName" "$wc_file")
        group=$(yq eval ".clusters[$i].spec.clusterGroupName" "$wc_file")
        proxy=$(yq eval ".clusters[$i].spec.proxyName // \"\"" "$wc_file")
        registry=$(yq eval ".clusters[$i].spec.imageRegistry // \"\"" "$wc_file")
        
        # Build the command
        cmd="tanzu tmc mc wc manage \"$name\" -m \"$mgmt\" -p \"$prov\" --cluster-group \"$group\""
        [[ -n "$proxy" && "$proxy" != "null" ]] && cmd+=" --proxy-name \"$proxy\""
        [[ -n "$registry" && "$registry" != "null" ]] && cmd+=" --image-registry \"$registry\""

	  echo $cmd
         eval $cmd
         if [ $? -eq 0 ]; then
           onboarded_cluster_name="$mgmt.$prov.$name"
           if ! grep -qxF "$onboarded_cluster_name" "$ONBOARDED_CLUSTER_INDEX_FILE"; then
             # If it doesn't exist, append it
             echo "$onboarded_cluster_name" >> "$ONBOARDED_CLUSTER_INDEX_FILE"
           fi
         fi
    done
done < "clusters/mc_registered.txt"