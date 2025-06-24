#! /bin/bash

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

source $SCRIPT_DIR/log.sh
source $SCRIPT_DIR/sm-api-call.sh

import_rolebindings() {
    rolebindings=$1
    scope=$2
    resource_name=$3
    params=$4

    if [ ! -z $resource_name ]; then
        resource_name="/$resource_name"
    fi

    if [ ! -z $params ]; then
        params="?$params"
    fi

    url="v1alpha1/${scope}:iam${resource_name}${params}"
    curl_api_call -X PUT -d "@$rolebindings" "$url"
}

generate_policy_spec() {
   scope=$1
   name=$2
   output=$3

   pushd $SCRIPT_DIR/../policies/assignments/$scope > /dev/null
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
          
           policy="$output/${name}.yaml"
           yq e -n ".fullName.name = \"$policy_name\" | .spec = load(\"$src_policies\").effective[$i].spec.policySpec" -o yaml > $policy
       done
   done
   popd
}