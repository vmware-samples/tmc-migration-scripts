#!/bin/bash
# Resource: Proxy Configuration(Under Administration)

DIR=proxy
DATA_DIR=data

if [ -d $DIR ]; then
  rm -rf $DIR/*
fi
mkdir -p $DIR/$DATA_DIR

tanzu tmc account credential list -o yaml | \
  yq eval -o=json - | jq '.' | \
  jq 'del(.totalCount)' | \
  jq '.credentials |=map(select(.spec.capability == "PROXY_CONFIG"))' | \
  yq eval -P -  > "$DIR/$DATA_DIR/proxies.yaml"