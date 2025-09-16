#! /bin/bash

SCRIPT_DIR=$PWD/$(dirname "${BASH_SOURCE[0]}")

source $SCRIPT_DIR/log.sh
source $SCRIPT_DIR/sm-api-call.sh

check_env() {
    if [ -z "${ADMIN_IDP_GROUP:-}" ] || [ -z "${MEMBER_IDP_GROUP:-}" ]; then
        log error "Environment variables ADMIN_IDP_GROUP and MEMBER_IDP_GROUP must be set, exiting..."
	exit 1
    fi
}

check_env

update_default_group() {
   local rolebindings="${@:-$(</dev/stdin)}"
   echo "$rolebindings" | jq --arg adminGroup "${ADMIN_IDP_GROUP}" \
      --arg memberGroup "${MEMBER_IDP_GROUP}" \
      '.roleBindings[].subjects[] |= if .kind=="GROUP"
        then
          if .name=="tmc:admin"
          then
            .name=$adminGroup
          elif .name=="tmc:member"
          then
            .name=$memberGroup
          else
            .
          end
        else
          .
        end'
}

import_rolebindings() {
    local rolebindings=$1
    local scope=$2
    local resource_name=$3
    local params=$4

    if [ ! -z $resource_name ]; then
        resource_name="/$resource_name"
    fi

    if [ ! -z $params ]; then
        params="?$params"
    fi

    url="v1alpha1/${scope}:iam${resource_name}${params}"
    curl_api_call -X PUT -d "@$rolebindings" "$url"
    echo ""
}

generate_policy_spec() {
   local scope=$1
   local output=$2

   mkdir -p $output

   pushd $SCRIPT_DIR/../data/policies/assignments/$scope > /dev/null
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

           policy="$output/${name}_${policy_name}.yaml"
           yq e -n ".fullName.name = \"$policy_name\" | .spec = load(\"$src_policies\").effective[$i].spec.policySpec" -o yaml > $policy
       done
   done
   popd > /dev/null
}

