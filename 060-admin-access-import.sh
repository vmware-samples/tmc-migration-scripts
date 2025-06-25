#!/bin/bash
# Resource: Access (Under Administration)

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
source "$SCRIPT_DIR"/utils/sm-api-call.sh
DATA_DIR="$SCRIPT_DIR"/data/credential-access

if [ ! -d $DATA_DIR ]; then
  echo "Nothing to do without directory $DATA_DIR, please backup data first"
  exit 0
fi

for file in $DATA_DIR/*; do
  if [ -f "$file" ]; then
    filename=`basename $file .yaml`
    echo "Start to check $filename"
    result=($(echo "$filename" | awk -F'---' '{print $1,$2}'))
    policyListLen=`cat "$file" | yq eval -o=json - | jq '.policyList | length'`
    if [ "$policyListLen" = "1" ]; then
      echo "Ignore built-in role $filename"
    fi

    if [ "$policyListLen" != "1" ]; then
      echo "Start to create $filename"
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
