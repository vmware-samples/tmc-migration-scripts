#! /bin/bash
set +x

source utils/log.sh
source utils/saas-api-call.sh

export_org_rolebindings() {
    role_bindings=$1
    tanzu tmc iam list -s organization -o json > $role_bindings
}

export_rolebindings() {
    uid=$1
    role_bindings=$2
    url="v1alpha1/iam/effective?searchScope.targetResourceUid=$uid"

    outputs=$(curl_api_call -X GET "$url")
    if [ $? -ne 0 ]; then
        log error "Failed to call api $url"
    fi

    echo "$outputs" | jq '.' > $role_bindings
}

log "************************************************************************"
log "* Exporting Access Policies from TMC SaaS ..."
log "************************************************************************"

DATA_DIR="data"
DIR="$DATA_DIR/policies/iam"

mkdir -p $DIR

org_scope="$DIR/organization"
mkdir -p $org_scope

log info "Exporting rolebindings on organization ..."
org_rolebindings="$org_scope/rolebindings.json"
export_org_rolebindings "$org_rolebindings"

workspace_scope="$DIR/workspaces"
mkdir -p $workspace_scope

log info "Exporting rolebindings on workspaces ..."
workspaces="$DATA_DIR/workspace/workspaces.yaml"
yq '.workspaces[] | [.fullName.name, .meta.uid] | @tsv' $workspaces | \
while IFS=$'\t' read -r name uid
do
    workspace_rolebindings="$workspace_scope/$name.json"
    log info "Exporting rolebindings on workspace $name ..."
    export_rolebindings "$uid" "$workspace_rolebindings"
done

clustergroup_scope="$DIR/clustergroups"
mkdir -p $clustergroup_scope

log info "Exporting rolebindings on clustergroups ..."
clustergroups="$DATA_DIR/clustergroup/clustergroups.yaml"
yq '.clusterGroups[] | [.fullName.name, .meta.uid] | @tsv' $clustergroups | \
while IFS=$'\t' read -r name uid
do
    clustegroup_rolebindings="$clustergroup_scope/$name.json"
    log info "Exporting rolebindings on clustergroup $name ..."
    export_rolebindings "$uid" "$clustegroup_rolebindings"
done

cluster_scope="$DIR/clusters"
mkdir -p $cluster_scope

log info "Exporting rolebindings on clusters ..."
clusters="$cluster_scope/clusters.yaml"
tanzu tmc cluster list -oyaml > $clusters

yq '.clusters[] | [.fullName.managementClusterName, .fullName.provisionerName, .fullName.name, .meta.uid] | @tsv' $clusters | \
while IFS=$'\t' read -r mgmt prvn name uid
do
    # skip empty data
    if [ -z $name ]; then
        continue
    fi
    cluster_rolebindings="$cluster_scope/${mgmt}_${prvn}_${name}.json"
    log info "Exporting rolebindings on cluster /${mgmt}/${prvn}/${name} ..."
    export_rolebindings "$uid" "$cluster_rolebindings"
done

namespace_scope="$DIR/namespaces"
mkdir -p $namespace_scope

log info "Exporting rolebindings on namespaces ..."
namespaces_path="data/cluster-namespaces"
for namespace in `find $namespaces_path -name '*.yml'`
do
    yq '[.fullName.managementClusterName, .fullName.provisionerName, .fullName.clusterName, .fullName.name, .meta.uid] | @tsv' $namespace | \
    while IFS=$'\t' read -r mgmt prvn cls name uid
    do
        namespace_rolebindings="$namespace_scope/${mgmt}_${prvn}_${cls}_${name}.json"
        log info "Exporting rolebindings on namespace /${mgmt}/${prvn}/${cls}/${name} ..."
        export_rolebindings "$uid" "$namespace_rolebindings"
    done
done