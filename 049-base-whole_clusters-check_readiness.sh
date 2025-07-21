source utils/sm-api-call.sh

CLUSTER_DATA_DIR="data/clusters"
MIN_VERSION="1.28.0"
ONBOARDED_CLUSTER_INDEX_FILE="$CLUSTER_DATA_DIR/onboarded-clusters-name-index"

#===========================================================================#
# After onboard all the managed clusters, wait for them to be totally ready.
# Check the onboarded clusters recorded in $ONBOARDED_CLUSTER_INDEX_FILE.
#===========================================================================#
INTERVAL=30   # seconds between checks
TIMEOUT=1800  # 30 minutes in seconds
START_TIME=$(date +%s)

echo "Checking cluster readiness..."

while true; do
  non_ready=0

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines
    [[ -z "$line" ]] && continue

    IFS='.' read -r management_cluster provisioner cluster <<< "$line"

    if [[ -z "$management_cluster" || -z "$provisioner" || -z "$cluster" ]]; then
      echo "Invalid cluster data: $line"
      continue
    fi

    echo "Checking cluster: $cluster (management_cluster: $management_cluster, provisioner: $provisioner)"
    
    cluster_api="v1alpha1/clusters/$cluster?full_name.managementClusterName=$management_cluster&full_name.provisionerName=$provisioner"
    output=$(curl_api_call $cluster_api 2>/dev/null || true)
    #output=$(tanzu tmc cluster get "$cluster" -m "$management_cluster" -p "$provisioner" -o yaml 2>/dev/null || true)

    if [[ -z "$output" ]]; then
      echo "Failed to get cluster info for $cluster"
      ((non_ready++))
      continue
    fi

    phase=$(echo "$output" | yq '.cluster.status.health' 2>/dev/null || echo "UNKNOWN")

    echo "Cluster '$cluster' health: $phase"

    if [[ "$phase" != "HEALTHY" ]]; then
      ((non_ready++))
    fi
  done < "$ONBOARDED_CLUSTER_INDEX_FILE"

  if [[ "$non_ready" -eq 0 ]]; then
    echo "✅ All clusters are READY."
    exit 0
  fi

  NOW=$(date +%s)
  ELAPSED=$((NOW - START_TIME))

  if [[ "$ELAPSED" -ge "$TIMEOUT" ]]; then
    echo "❌ Timeout reached. $non_ready clusters not READY."
    exit 1
  fi

  echo "⏳ $non_ready clusters not READY. Retrying in ${INTERVAL}s..."
  sleep "$INTERVAL"
done
