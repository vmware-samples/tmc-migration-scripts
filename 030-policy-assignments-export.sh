#! /bin/bash

source utils/log.sh

log "************************************************************************"
log "* Exporting Policy Assignments from TMC SaaS ..."
log "************************************************************************"

DIR="policies/assigments"
mkdir -p $DIR

org_scope="$DIR/organization"
mkdir -p $org_scope

log info "Exporting policies on organization ..."
org_policies="$org_scope/policies.yaml"
tanzu mission-control policy list -s organization -o yaml > $org_policies

workspace_scope="$DIR/workspaces"
mkdir -p $workspace_scope

log info "Exporting policies on workspaces ..."
workspaces="workspaces/workspaces.yaml"
yq '.workspaces[] | .fullName.name' $workspaces | \
while read -r name
do
    workspace_policies="$workspace_scope/$name.yaml"
    tanzu mission-control policy list -s workspace -n $name -o yaml > $workspace_policies
done

clustergroup_scope="$DIR/clustergroups"
mkdir -p $clustergroup_scope

log info "Exporting policies on clustergroups ..."
clustergroups="clustergroups/clustergroups.yaml"
yq '.clusterGroups[] | .fullName.name' $clustergroups | \
while read -r name
do
    clustegroup_policies="$clustergroup_scope/$name.yaml"
    tanzu mission-control policy list -s clustergroup -n $name -o yaml > $clustegroup_policies
done

cluster_scope="$DIR/clusters"
mkdir -p $cluster_scope

log info "Exporting policies on clusters ..."
cluster_path="clusters/"
for cluster_file in `find $cluster_path -name '*.yaml'`
do
    yq '.clusters[] | [.fullName.managementClusterName, .fullName.provisionerName, .fullName.name] | @tsv' $clusters | \
    while IFS=$'\t' read -r mgmt prvn name
    do
        # skip empty data
        if [ -z $name ]; then
            continue
        fi
    cluster_policies="$cluster_scope/${mgmt}_${prvn}_${name}.yaml"
    tanzu mission-control policy list -s cluster -n $name -m $mgmt -p $prvn -o yaml > $cluster_policies
    done
done