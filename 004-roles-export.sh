#!/bin/bash
# Resource: Role (Under Administration)
# Only export customized role by users.

DIR=role
DATA_DIR=data

if [ -d $DIR ]; then
  rm -rf $DIR/*
fi

mkdir -p $DIR/$DATA_DIR

tanzu tmc iam role list -o yaml | \
  yq eval -o=json - | jq '.' | \
  jq 'del(.totalCount)' | \
  jq '.roles |=map(select(.spec.isInbuilt == false))' | \
  yq eval -P -  > "$DIR/$DATA_DIR/roles.yaml"