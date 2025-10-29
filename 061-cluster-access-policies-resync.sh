#! /bin/bash

source utils/common.sh
source utils/kubeconfig.sh

register_last_words "Resync rolebindings on clusters and namespaces"

TMC_NAMESPACE="vmware-system-tmc"

DATA_DIR="data"
SRC_DIR="$DATA_DIR/policies/iam"
TEMP_DIR="$PWD/$SRC_DIR/$(date +%s)"
TEMPKUBECONFIG="$TEMP_DIR/kubeconfig"

# Create temp directory
mkdir -p "$TEMP_DIR"

export KUBECONFIG=$TEMPKUBECONFIG

log "************************************************************************"
log "* Resync Rolebindings on Clusters and Namespaces ..."
log "************************************************************************"

if [[ -z "$ONBOARDED_CLUSTER_INDEX_FILE" ]]; then
    log error "ONBOARDED_CLUSTER_INDEX_FILE is not set"
    exit 1
elif [[ ! -f "$ONBOARDED_CLUSTER_INDEX_FILE" ]]; then
    log error "$ONBOARDED_CLUSTER_INDEX_FILE doesn't exist"
    exit 1
fi

while IFS="." read -r mgmt prvn cls; do
    log info "Connecting to the cluster $mgmt/$prvn/$cls..."
    if ! get_kubeconfig ${cls} ${prvn} ${mgmt} ${TEMPKUBECONFIG}; then
        log error "Failed to get kubeconfig for cluster $mgmt/$prvn/$cls, skip resyncing access policies for this cluster"
        continue
    fi

    # Verify cluster connection
    if ! kubectl cluster-info >/dev/null 2>&1; then
        log error "Failed to connect to cluster $mgmt/$prvn/$cls, skip resyncing access policies for this cluster"
        continue
    fi

    log info "Delete stale custom cluster roles for $mgmt/$prvn/$cls ..."
    kubectl get customrole --no-headers -o custom-columns=":metadata.name" | while read -r role; do
        kubectl delete clusterrole $role
    done

    org_id=$(kubectl -n $TMC_NAMESPACE get cm stack-config -o jsonpath='{.data.org_id}' 2>/dev/null)
    if [[ -z "$org_id" ]]; then
        log error "Failed to get org_id for the cluster $mgmt/$prvn/$cls, skip resyncing access policies for this cluster"
        continue
    fi
  
    log info "Delete stale cluster rolebindings on $mgmt/$prvn/$cls ..."
    kubectl get clusterrolebinding --no-headers -o custom-columns=":metadata.name" -A | while read -r binding; do
        if [[ $binding =~ org-.*-rbac.authorization.k8s.io ]] && [[ ! $binding =~ $org_id ]]; then
            kubectl delete clusterrolebinding $binding
        fi
    done

    log info "Delete stale rolebindings for $mgmt/$prvn/$cls ..."
    kubectl get rolebinding --no-headers -o custom-columns=":metadata.name,:metadata.namespace" | while read -r binding namespace; do
        if [[ $binding =~ org-.*-rbac.authorization.k8s.io ]] && [[ ! $binding =~ $org_id ]]; then
            kubectl delete rolebinding $binding -n $namespace
        fi
    done

    log info "Restart policy sync extension to resync access policies ..."
    kubectl rollout restart deployment policy-sync-extension -n $TMC_NAMESPACE
done < $ONBOARDED_CLUSTER_INDEX_FILE