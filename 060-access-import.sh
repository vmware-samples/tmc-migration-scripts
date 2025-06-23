#!/bin/bash
# Resource: Access (Under Administration)

source 033-sm-api-call.sh
DIR=credential-access
DATA_DIR=data

if [ ! -d $DIR ]; then
  echo "Nothing to do without directory $DIR, please backup data first"
  exit 0
fi

for file in "$DIR"/$DATA_DIR/*; do
  if [ -f "$file" ]; then
    filename=`basename $file .yaml`
    result=($(echo "$filename" | awk -F'---' '{print $1,$2}'))
    policyListLen=`cat "$file" | yq eval -o=json - | jq '.policyList | length'`
    if [ "$policyListLen" != "1" ]; then

      roleBindings=`cat "$file" | yq eval -o=json - | \
        jq -c '.policyList[0]' | jq -c 'del(.meta)'`

      curl_api_call -X PUT -d "$roleBindings" \
        "v1alpha1/account/credentials:iam/${result[1]}"

      if [ $? -eq 0 ]; then
        echo "Successfully created role binding for credential $file"
      fi
    fi
  fi
done
