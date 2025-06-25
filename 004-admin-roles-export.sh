#!/bin/bash
# Resource: Role (Under Administration)
# Only export customized role by users.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DATA_DIR="$SCRIPT_DIR"/data/role

if [ -d $DATA_DIR ]; then
  rm -rf $DATA_DIR/*
fi

mkdir -p $DATA_DIR

tanzu tmc iam role list -o yaml | \
  yq eval -o=json - | jq '.' | \
  jq 'del(.totalCount)' | \
  jq '.roles |=map(select(.spec.isInbuilt == false))' | \
  yq eval -P -  > "$DATA_DIR/roles.yaml"