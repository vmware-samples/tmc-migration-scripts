#! /bin/bash

source utils/log.sh

DATA_DIR="/path/to/data"
TEMP_DIR=$(mktemp -d)
SRC_DIR="$DATA_DIR/policies"

generate_policy_spec() {
   scope=$1
   name=$2

   pushd $SRC_DIR/$scope > /dev/null
   for name in $(ls *.yaml | sed 's/.yaml//')
   do
       src_policies="$name.yaml"
       if [ ! -f $src_policies ]; then
           log info "[SKIP] policy file for $scope:$name is not found"
           continue
       fi

       total_count=$(yq '.totalCount' $src_policies)
       for ((i = 0; i < $total_count; i++))
       do
           policy_name=$(yq e ".effective[$i].spec.sourcePolicy.rid" $src_policies | awk -F: '{print $NF}')

           inherited=$(yq e ".effective[$i].spec.inherited" $src_policies)
           if [ $inherited == true ]; then
               log info "[SKIP] inherited policy:${policy_name}"
               continue
           fi
          
           policy="$TEMP_DIR/$scope/${name}.yaml"
           yq e -n ".fullName.name = \"$policy_name\" | .spec = load(\"$src_policies\").effective[$i].spec.policySpec" -o yaml > $policy
       done
   done
   popd
}

import_org_policies() {
   scope="organization"
   policies_temp="$TEMP_DIR/$scope"
   mkdir -p $policies_temp

   generate_policy_spec "$scope" "$name"

   pushd $policies_temp > /dev/null
       for p_file in $(ls *.yaml)
       do
           tanzu mission-control policy create -s organization -f $p_file
       done
   popd
}

import_clustergroup_policies() {
   scope="clustergroups"
   policies_temp="$TEMP_DIR/$scope"
   mkdir -p $policies_temp

   generate_policy_spec "$scope" "$name"

   pushd $policies_temp > /dev/null
       for p_file in $(ls *.yaml)
       do
           cg_name=$(log info "$p_file" | sed 's/.yaml$//g')

           yq e -i ".fullName.clusterGroupName = \"$cg_name\"" $p_file

           tanzu mission-control policy create -s clustergroup -f $p_file
       done
   popd
}

import_workspace_policies() {
   scope="workspaces"
   policies_temp="$TEMP_DIR/$scope"
   mkdir -p $policies_temp

   generate_policy_spec "$scope" "$name"

   pushd $policies_temp > /dev/null
       for p_file in $(ls *.yaml)
       do
           ws_name=$(log info "$p_file" | sed 's/.yaml$//g')

           yq e -i ".fullName.workspaceName = \"$ws_name\"" $p_file

           tanzu mission-control policy create -s workspace -f $p_file
       done
   popd
}

import_cluster_policies() {
   scope="clusters"
   policies_temp="$TEMP_DIR/$scope"
   mkdir -p $policies_temp

   generate_policy_spec "$scope" "$name"

   pushd $policies_temp > /dev/null
       for p_file in $(ls *.yaml)
       do
           cls_full_name=$(log info "$p_file" | sed 's/.yaml$//g')

           IFS='_' read -r mgmt prvn cls <<< "$cls_full_name"

           yq e -i ".fullName.managementClusterName = \"$mgmt\" | .fullName.provisionerName = \"$prvn\" | .fullName.clusterName = \"$cls\"" $p_file

          tanzu mission-control policy create -s cluster -f $p_file
       done
   popd
}

log "************************************************************************"
log "* Import Policy Assignments to TMC SM ..."
log "************************************************************************"

log info "Importing policies on organization ..."
import_org_policies

log info "Importing policies on clustergroups ..."
import_clustergroup_policies

log info "Importing policies on workspaces ..."
import_workspace_policies

log info "Importing policies on clusters ..."
import_cluster_policies
