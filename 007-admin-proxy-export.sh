#!/bin/bash
# Resource: Proxy Configuration(Under Administration)

DATA_DIR=data/proxy

if [ -d $DATA_DIR ]; then
  rm -rf $DATA_DIR/*
fi
mkdir -p $DATA_DIR

tanzu tmc account credential list -o yaml | \
  yq eval -o=json - | jq '.' | \
  jq 'del(.totalCount)' | \
  jq '.credentials |=map(select(.spec.capability == "PROXY_CONFIG"))' | \
  yq eval -P -  > "$DATA_DIR/proxies.yaml"