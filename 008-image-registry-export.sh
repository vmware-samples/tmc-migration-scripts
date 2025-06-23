#!/bin/bash
# Resource: Local Image Registry (Under Administration)

DIR=image-registry
DATA_DIR=data

if [ -d $DIR ]; then
  rm -rf $DIR/*
fi
mkdir -p $DIR/$DATA_DIR

tanzu tmc account credential list -o yaml | \
  yq eval -o=json - | jq '.' | \
  jq 'del(.totalCount)' | \
  jq '.credentials |=map(select(.spec.capability == "IMAGE_REGISTRY"))' | \
  yq eval -P -  > "$DIR/$DATA_DIR/image-registries.yaml"