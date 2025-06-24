#!/bin/bash

MC_LIST_YAML_FILE=clusters/mc_list.yaml
MC_KUBECONFIG_INDEX_FILE=clusters/mc-kubeconfig-index-file
REGISTERED_FILE="clusters/mc_registered.txt"
PLACEHOLDER_TEXT="/path/to/the/real/mc_kubeconfig/file"

# If the $MC_KUBECONFIG_INDEX_FILE file is NOT completely updated, then stop to proceed.
if grep -q "$PLACEHOLDER_TEXT" "$MC_KUBECONFIG_INDEX_FILE"; then
  echo "⚠️  Warning: Placeholder text '$PLACEHOLDER_TEXT' found in $MC_KUBECONFIG_INDEX_FILE. Please replace it."
  exit 1
fi

# Clean up registration resources and recreate the config.
function prepare() {
    namespaces=$(kubectl get ns --no-headers -o custom-columns=":metadata.name" | grep '^svc-tmc-')

    for ns in $namespaces; do
        echo "Checking namespace: $ns"

        # Delete the agentinstall if it exists.
        delete_agent_installs "$ns"
        # Uninstall the pre-installation.
        uninstall_stale_res "$ns"
        # Clean the uninstall operation resource.
        delete_agent_installs "$ns"

        # Delete the agent config it exists.
        delete_agent_config "$ns"
        # Create agent config.
        create_agent_config "$ns"
    done
}

function delete_agent_config() {
    local ns="$1"

    # Check and delete AgentConfig if exists
    if kubectl get agentconfig -n "$ns" &>/dev/null; then
        echo "Deleting AgentConfig(s) in $ns..."
        kubectl delete agentconfig --all -n "$ns"
    else
        echo "No AgentConfig in $ns"
    fi
}

function delete_agent_installs(){
    local ns="$1"

    # Check and delete AgentInstall if exists
    if kubectl get agentinstall -n "$ns" &>/dev/null; then
        echo "🧹 Deleting AgentInstall(s) in $ns..."
        kubectl delete agentinstall --all -n "$ns"
    else
        echo "No AgentInstall in $ns"
    fi
}

function create_agent_config() {
    local namespace="$1"

    ENDPOINT=$(tanzu context get $TMC_SM_CONTEXT | yq .globalOpts.endpoint)
    DOMAIN=$(echo "$ENDPOINT" | cut -d':' -f1)
    CA_CERTIFICATE=$(openssl s_client -connect $ENDPOINT -showcerts </dev/null 2>/dev/null | openssl x509 -outform PEM)

    cat <<EOF | kubectl apply -f -
apiVersion: "installers.tmc.cloud.vmware.com/v1alpha1"
kind: "AgentConfig"
metadata:
  name: "tmc-agent-config"
  namespace: "$namespace"
spec:
  caCerts: |-
$(echo "$CA_CERTIFICATE" | sed 's/^/    /')
  allowedHostNames:
    - $DOMAIN
EOF
}

function uninstall_stale_res() {
    local namespace="$1"

    echo "Apply uninstall operation"

    cat <<EOF | kubectl apply -f -
apiVersion: installers.tmc.cloud.vmware.com/v1alpha1
kind: AgentInstall
metadata:
  name: tmc-agent-installer-config
  namespace: "$namespace"
spec:
  operation: UNINSTALL
EOF

wait_for_pods_cleaned $namespace
}

function wait_for_pods_cleaned() {
    local namespace="$1"

    TIMEOUT_SECONDS=300  # 5 minutes
    SLEEP_INTERVAL=5

    echo "Waiting for all pods in namespace '$namespace' to terminate..."

    elapsed=0
    while true; do
        # Get number of pods
        pod_count=$(kubectl get pods -n "$namespace" --no-headers 2>/dev/null | grep -v '^tmc-agent-installer-' | wc -l)

        # If no pods, break the loop
        if [[ "$pod_count" -eq 0 ]]; then
            echo "All pods in namespace '$namespace' are gone."
            break
        fi

        if [[ "$elapsed" -ge "$TIMEOUT_SECONDS" ]]; then
            echo "Timeout reached. Still $pod_count pod(s) remaining in namespace '$NAMESPACE'."
            exit 1
        fi

        echo "$pod_count pod(s) remaining... waited ${elapsed}s"

        sleep "$SLEEP_INTERVAL"
        ((elapsed+=SLEEP_INTERVAL))

    done
}


# Reset tracking file
: > "$REGISTERED_FILE"

# Iterate through clusters
index=0
total=$(yq '.managementClusters | length' $MC_LIST_YAML_FILE)

while [ "$index" -lt "$total" ]; do
  health=$(yq ".managementClusters[$index].status.health" $MC_LIST_YAML_FILE)
  name=$(yq ".managementClusters[$index].fullName.name" $MC_LIST_YAML_FILE)

  if [ "$health" == "HEALTHY" ] && [[ "$name" != "aks" && "$name" != "eks" && "$name" != "attached" ]]; then
    orgId=$(yq ".managementClusters[$index].fullName.orgId" $MC_LIST_YAML_FILE)
    file="clusters/mc_${orgId}_${name}.yaml"

    echo "Processing mc $name [health=$health]"

    # Save cluster data without .status field.
    yq "del(.managementClusters[$index].status) | .managementClusters[$index]" $MC_LIST_YAML_FILE > "$file"
    # Remove orgId.
    yq -i 'del(.fullName.orgId)' $file

    # Look up the kubeconfig file path from the provided index file
    KUBECONFIG_PATH=$(grep "^$name:" "$MC_KUBECONFIG_INDEX_FILE" | awk '{print $2}')
    export KUBECONFIG=$KUBECONFIG_PATH

    # Prepare.
    prepare

    # Register the cluster using cli.
    if tanzu tmc mc get "$name" >/dev/null 2>&1; then
      tanzu tmc mc reregister "$name" --kubeconfig "$KUBECONFIG_PATH"
    else
      tanzu tmc mc register "$name" -f "$file" --kubeconfig "$KUBECONFIG_PATH"
    fi
    
    # Track the name of successfully registered management cluster for later use.
    echo "$name" >> "$REGISTERED_FILE"
  fi

  index=$((index + 1))
done

# Mange the workload clusters.
MIN_VERSION="1.28.0"
ONBOARDED_CLUSTER_INDEX_FILE="clusters/onboarded-clusters-name-index"

# Strip v prefix and metadata from version (e.g., v1.29.4+ -> 1.29.4)
sanitize_version() {
  echo "$1" | sed -E 's/^v//' | cut -d'+' -f1
}

compare_versions() {
  # Returns 0 if $1 >= $2
  [ "$(printf "%s\n%s" "$2" "$1" | sort -V | head -n1)" = "$2" ]
}

# Read management cluster name from $REGISTERED_FILE.
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

	    echo "Run $cmd"
        eval $cmd
        if [ $? -eq 0 ]; then
            onboarded_cluster_name="$mgmt.$prov.$name"
            if ! grep -qxF "$onboarded_cluster_name" "$ONBOARDED_CLUSTER_INDEX_FILE"; then
                # If it doesn't exist, append it
                echo "$onboarded_cluster_name" >> "$ONBOARDED_CLUSTER_INDEX_FILE"
            fi
        fi
    done
done < $REGISTERED_FILE