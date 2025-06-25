#!/bin/bash
# Resource: Local Image Registry (Under Administration)

SCRIPT_DIR=$(dirname "$0")
DATA_DIR="$SCRIPT_DIR"/data/image-registry

if [ -d $DATA_DIR ]; then
  rm -rf $DATA_DIR/*
fi
mkdir -p $DATA_DIR

tanzu tmc account credential list -o yaml | \
  yq eval -o=json - | jq '.' | \
  jq 'del(.totalCount)' | \
  jq '.credentials |=map(select(.spec.capability == "IMAGE_REGISTRY"))' | \
  yq eval -P -  > "$DATA_DIR/image-registries.yaml"