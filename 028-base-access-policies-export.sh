#! /bin/bash
set +x

source utils/log.sh

# This script depends on below environment variables
# export TMC_ENDPOINT=""
# export TMC_ACCESS_TOKEN=""

export_org_rolebindings() {
    role_bindings=$1
    tanzu tmc iam list -s organization -o json > $role_bindings
}

export_rolebindings() {
    uid=$1
    role_bindings=$2
    url="$TMC_ENDPOINT/v1alpha1/iam/effective?searchScope.targetResourceUid=$uid"
    curl --fail -H "Authorization: Bearer $TMC_ACCESS_TOKEN" -X GET $url | jq '.' > $role_bindings
}

log "************************************************************************"
log "* Exporting Access Policies from TMC SaaS ..."
log "************************************************************************"

DIR="policies/iam"

mkdir -p $DIR

org_scope="$DIR/organization"
mkdir -p $org_scope

log info "Exporting rolebindings on organization ..."
org_rolebindings="$org_scope/rolebindings.json"
export_org_rolebindings "$org_rolebindings"

workspace_scope="$DIR/workspaces"
mkdir -p $workspace_scope

log info "Exporting rolebindings on workspaces ..."
workspaces="workspace/data/workspaces.yaml"
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
clustergroups="clustergroup/data/clustergroups.yaml"
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
cluster_path="clusters/"
for cluster_file in `find $cluster_path -name '*.yaml'`
do
    yq '.clusters[] | [.fullName.managementClusterName, .fullName.provisionerName, .fullName.name, .meta.uid] | @tsv' $cluster_file | \
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