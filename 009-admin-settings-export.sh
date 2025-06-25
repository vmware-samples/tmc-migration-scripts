#!/bin/bash
# Resource: Settings (Under Administration)

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DATA_DIR="$SCRIPT_DIR"/data/setting
scopes=("cluster" "clustergroup" "organization")

if [ -d $DATA_DIR ]; then
  rm -rf $DATA_DIR/*
fi

mkdir -p $DATA_DIR

for scope in "${scopes[@]}"; do
  mkdir -p $DATA_DIR/$scope
  tanzu tmc setting list --scope $scope -o yaml | \
    yq eval -o=json - | jq '.' | \
    jq 'del(.totalCount)' | \
    jq '.effective |=map(select(.spec.inherited == false))' | \
    yq eval -P -  > "$DATA_DIR/$scope/settings.yaml"
done
