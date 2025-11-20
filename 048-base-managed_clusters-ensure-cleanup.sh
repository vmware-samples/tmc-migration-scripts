source "$(dirname "${BASH_SOURCE[0]}")"/utils/log.sh

# Global variables
CLUSTER_DATA_DIR="data/clusters"
MC_KUBECONFIG_INDEX_FILE="$CLUSTER_DATA_DIR/mc-kubeconfig-index-file"

# Common function to validate kubeconfig index file
function validate_kubeconfig_index() {
  if [[ ! -f "$MC_KUBECONFIG_INDEX_FILE" ]]; then
    log error "No management cluster kubeconfig index file found at $MC_KUBECONFIG_INDEX_FILE"
    return 1
  fi
  
  return 0
}

# Common function to get workload cluster file path
function get_wc_file() {
  local mc_name="$1"
  echo "$CLUSTER_DATA_DIR/wc_of_${mc_name}.yaml"
}

# Callback function for processing cluster annotations
function process_cluster_annotations() {
  local name="$1"
  local prov="$2"
  local mc_name="$3"
  local kubeconfig_path="$4"
  
  log info "Removing target annotations from cluster: $name in namespace: $prov"
  
  # Define specific annotations to remove
  local annotations_to_remove=(
    "run.tanzu.vmware.com/agent-uid"
    "run.tanzu.vmware.com/vmware-system-tmc-cluster-group"
    "run.tanzu.vmware.com/vmware-system-tmc-applied"
    "run.tanzu.vmware.com/vmware-system-tmc-managed"
    "run.tanzu.vmware.com/tmc-already-attached"
    "run.tanzu.vmware.com/proxy-name"
    "run.tanzu.vmware.com/image-registry"
    "run.tanzu.vmware.com/auto-scaling"
    "run.tanzu.vmware.com/auto-scaler-status"
    "run.tanzu.vmware.com/kcp-status"
    "run.tanzu.vmware.com/nodepool-status"
  )
  
  # Build kubectl annotate command to remove annotations
  local annotate_cmd="kubectl --kubeconfig=\"$kubeconfig_path\" annotate cluster \"$name\" -n \"$prov\""
  for annotation in "${annotations_to_remove[@]}"; do
    annotate_cmd+=" \"$annotation\"-"
  done
  
  # Execute the command (kubectl will ignore non-existent annotations)
  if eval "$annotate_cmd" 2>/dev/null; then
    log info "Successfully processed annotations for cluster $name"
  else
    log error "Failed to remove annotations from cluster $name."
    return 1
  fi
  
  return 0
}

# Function to generate and save kubeconfig for a workload cluster
# Returns: The path to the generated kubeconfig file, or empty string on failure
function generate_cluster_kubeconfig() {
  local cluster_name="$1"
  local provisioner_namespace="$2"
  local mc_kubeconfig="$3"
  local mc_name="$4"
  
  # Get the cluster's kubeconfig from the secret (using $clusterName-kubeconfig format)
  local cluster_kubeconfig_b64=$(kubectl --kubeconfig="$mc_kubeconfig" get secret "${cluster_name}-kubeconfig" -n "$provisioner_namespace" -o jsonpath='{.data.value}' 2>/dev/null)
  
  if [[ $? -ne 0 || -z "$cluster_kubeconfig_b64" ]]; then
    return 1
  fi
  
  # Create kubeconfigs directory if it doesn't exist
  local kubeconfig_dir="$CLUSTER_DATA_DIR/kubeconfigs"
  mkdir -p "$kubeconfig_dir"
  
  # Decode the kubeconfig and save to kubeconfigs directory with format: ${mc_name}_${prov}_${name}.kubeconfig
  local cluster_kubeconfig="$kubeconfig_dir/${mc_name}_${provisioner_namespace}_${cluster_name}.kubeconfig"
  echo "$cluster_kubeconfig_b64" | base64 -d > "$cluster_kubeconfig"
  
  if [[ $? -ne 0 ]]; then
    rm -f "$cluster_kubeconfig"
    return 1
  fi
  
  # Return the kubeconfig path
  echo "$cluster_kubeconfig"
  return 0
}

# Callback function for processing TMC agents
# Parameters: cluster_name, cluster_kubeconfig_path
function process_tmc_agents() {
  local name="$1"
  local cluster_kubeconfig="$2"
  
  log info "Checking TMC namespace for cluster: $name"
  
  # Check if vmware-system-tmc namespace exists
  local namespace_exists=$(kubectl --kubeconfig="$cluster_kubeconfig" get namespace vmware-system-tmc --ignore-not-found=true -o name 2>/dev/null)
  
  if [[ -z "$namespace_exists" ]]; then
    log info "No vmware-system-tmc namespace found in cluster $name, skipping cleanup..."
  else
    log info "Found vmware-system-tmc namespace in cluster $name, performing cleanup..."
    # https://techdocs.broadcom.com/us/en/vmware-tanzu/standalone-components/tanzu-mission-control-self-managed/1-4/tmc-self-managed-documentation/using-tmc/managing-clusters/remove-a-cluster-from-your-organization.html

    # Delete namespace
    kubectl --kubeconfig="$cluster_kubeconfig" delete namespace vmware-system-tmc --ignore-not-found=true --timeout=1m 2>/dev/null || true
    
    # Define TMC CRDs to delete
    local tmc_crds=(
      "extensions.clusters.tmc.cloud.vmware.com"
      "agents.clusters.tmc.cloud.vmware.com"
      "extensionresourceowners.clusters.tmc.cloud.vmware.com"
      "extensionintegrations.clusters.tmc.cloud.vmware.com"
      "extensionconfigs.intents.tmc.cloud.vmware.com"
    )
    
    # Delete CRDs
    for crd in "${tmc_crds[@]}"; do
      kubectl --kubeconfig="$cluster_kubeconfig" delete crd "$crd" --ignore-not-found=true 2>/dev/null || true
    done
    
    # Define TMC cluster roles to delete
    local tmc_cluster_roles=(
      "extension-updater-clusterrole"
      "extension-manager-role"
      "agent-updater-role"
      "vmware-system-tmc-psp-agent-restricted"
    )
    
    # Delete cluster roles
    for role in "${tmc_cluster_roles[@]}"; do
      kubectl --kubeconfig="$cluster_kubeconfig" delete clusterrole "$role" --ignore-not-found=true 2>/dev/null || true
    done
    
    # Define TMC cluster role bindings to delete
    local tmc_cluster_role_bindings=(
      "extension-updater-clusterrolebinding"
      "extension-manager-rolebinding"
      "agent-updater-rolebinding"
      "vmware-system-tmc-psp-agent-restricted"
    )
    
    # Delete cluster role bindings
    for binding in "${tmc_cluster_role_bindings[@]}"; do
      kubectl --kubeconfig="$cluster_kubeconfig" delete clusterrolebinding "$binding" --ignore-not-found=true 2>/dev/null || true
    done
    
    # Delete PSP
    kubectl --kubeconfig="$cluster_kubeconfig" delete psp vmware-system-tmc-agent-restricted --ignore-not-found=true 2>/dev/null || true
    
    # Wait up to 2 minutes for namespace to be deleted, then force delete if stuck
    local timeout=120
    local elapsed=0
    local interval=15
    
    while [[ $elapsed -lt $timeout ]]; do
      local namespace_status=$(kubectl --kubeconfig="$cluster_kubeconfig" get namespace vmware-system-tmc --ignore-not-found=true -o jsonpath='{.status.phase}' 2>/dev/null)
      
      if [[ -z "$namespace_status" ]]; then
        log info "Successfully deleted vmware-system-tmc namespace from cluster $name"
        break
      elif [[ "$namespace_status" == "Terminating" ]]; then
        log info "Namespace vmware-system-tmc is in Terminating state, waiting... (${elapsed}s/${timeout}s)"
        sleep $interval
        elapsed=$((elapsed + interval))
      else
        log error "Namespace vmware-system-tmc has unexpected status: $namespace_status"
        return 1
      fi
    done
    
    # If namespace is still stuck in Terminating after timeout, force delete
    local final_status=$(kubectl --kubeconfig="$cluster_kubeconfig" get namespace vmware-system-tmc --ignore-not-found=true -o jsonpath='{.status.phase}' 2>/dev/null)
    if [[ "$final_status" == "Terminating" ]]; then
      log warn "Namespace vmware-system-tmc is stuck in Terminating state after ${timeout}s, force deleting..."
      
      # Get the namespace JSON and remove finalizers
      kubectl --kubeconfig="$cluster_kubeconfig" get namespace vmware-system-tmc -o json 2>/dev/null | \
        jq '.spec.finalizers = []' | \
        kubectl --kubeconfig="$cluster_kubeconfig" replace --raw "/api/v1/namespaces/vmware-system-tmc/finalize" -f - 2>/dev/null || true
      
      log info "Force deleted vmware-system-tmc namespace from cluster $name"
    fi
  fi
  return 0
}

# Combined precheck function that processes both annotations and TMC agents per cluster
function precheck_clusters() {
  log info "Starting cluster precheck (annotations and TMC agents)..."
  
  # Read management cluster names and kubeconfig paths from index file
  while IFS=':' read -r mc_name kubeconfig_path; do
    # Trim leading and trailing spaces from kubeconfig_path
    kubeconfig_path=$(echo "$kubeconfig_path" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    # Skip empty lines
    [[ -z "$mc_name" || -z "$kubeconfig_path" ]] && continue

    # Check if the kubeconfig file exists
    if [[ ! -f "$kubeconfig_path" ]]; then
      log error "Kubeconfig file for management cluster $mc_name: $kubeconfig_path not found."
      return 1
    fi
    
    local wc_file=$(get_wc_file "$mc_name")
    
    if [[ ! -f "$wc_file" ]]; then
      log error "File of workload clusters on $mc_name: $wc_file not found."
      return 1
    fi
    
    log info "Using kubeconfig: $kubeconfig_path for management cluster: $mc_name"
    
    # Get cluster count
    local cluster_count=$(yq eval '.clusters | length' "$wc_file")
    
    # Process each cluster one by one
    for ((i=0; i<cluster_count; i++)); do
      local name=$(yq eval ".clusters[$i].fullName.name" "$wc_file")
      local prov=$(yq eval ".clusters[$i].fullName.provisionerName" "$wc_file")
      
      log info "=========================================="
      log info "Processing cluster $((i+1))/$cluster_count: $name (management cluster: $mc_name, namespace: $prov)"
      log info "=========================================="
      
      # Step 1: Process cluster annotations
      log info "Step 1/2: Checking and removing run.tanzu.vmware.com annotations..."
      process_cluster_annotations "$name" "$prov" "$mc_name" "$kubeconfig_path"
      if [[ $? -ne 0 ]]; then
        log error "Failed to process annotations for cluster $name"
        return 1
      fi
      
      # Step 2: Generate kubeconfig and process TMC agents
      log info "Step 2/2: Checking and cleaning up TMC agents..."
      local cluster_kubeconfig=$(generate_cluster_kubeconfig "$name" "$prov" "$kubeconfig_path" "$mc_name")
      
      if [[ $? -ne 0 || -z "$cluster_kubeconfig" ]]; then
        log error "Failed to generate kubeconfig for cluster $name."
        return 1
      fi
      
      # Process TMC agents with the generated kubeconfig
      process_tmc_agents "$name" "$cluster_kubeconfig"
      if [[ $? -ne 0 ]]; then
        log error "TMC agent cleanup encountered issues for cluster $name"
        return 1
      fi
      
      log info "Completed processing cluster: $name"
      echo ""
    done
  done < "$MC_KUBECONFIG_INDEX_FILE"
  
  log info "Cluster precheck completed."
}

# Main function to run all prechecks
function main() {
  # Validate kubeconfig index file once at the start
  validate_kubeconfig_index
  if [[ $? -ne 0 ]]; then
    log error "Validation failed. Exiting..."
    return 1
  fi
  
  # Process all clusters (annotations and TMC agents) one by one
  precheck_clusters
  if [[ $? -ne 0 ]]; then
    log error "Cluster precheck failed. Exiting..."
    return 1
  fi

  log info "Precheck completed successfully."
  return 0
}

main