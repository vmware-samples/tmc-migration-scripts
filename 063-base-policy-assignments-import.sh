#! /bin/bash

source utils/policy-helper.sh

TEMP_DIR=$(mktemp -d)
SRC_DIR="policies/assignments"

import_org_policies() {
   scope="organization"
   policies_temp="$TEMP_DIR/$scope"
   mkdir -p $policies_temp

   generate_policy_spec "$scope" "$name" "$policies_temp"

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

   generate_policy_spec "$scope" "$name" "$policies_temp"

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

   generate_policy_spec "$scope" "$name" "$policies_temp"

   pushd $policies_temp > /dev/null
       for p_file in $(ls *.yaml)
       do
           ws_name=$(log info "$p_file" | sed 's/.yaml$//g')

           yq e -i ".fullName.workspaceName = \"$ws_name\"" $p_file

           tanzu mission-control policy create -s workspace -f $p_file
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