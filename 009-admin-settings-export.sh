#!/bin/bash
# Resource: Settings (Under Administration)

DIR=setting
DATA_DIR=data
scopes=("cluster" "clustergroup" "organization")

if [ -d $DIR ]; then
  rm -rf $DIR/*
fi

mkdir -p $DIR/$DATA_DIR

for scope in "${scopes[@]}"; do
  mkdir -p $DIR/$DATA_DIR/$scope
  tanzu tmc setting list --scope $scope -o yaml | \
    yq eval -o=json - | jq '.' | \
    jq 'del(.totalCount)' | \
    jq '.effective |=map(select(.spec.inherited == false))' | \
    yq eval -P -  > "$DIR/$DATA_DIR/$scope/settings.yaml"
done
