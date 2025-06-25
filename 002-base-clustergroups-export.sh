#!/bin/bash
# Resource: Cluster group

SCRIPT_DIR=$(dirname "$0")
DATA_DIR="$SCRIPT_DIR"/data/clustergroup

if [ -d $DATA_DIR ]; then
  rm -rf $DATA_DIR/*
fi
mkdir -p $DATA_DIR

tanzu tmc clustergroup list -o yaml > "$DATA_DIR/clustergroups.yaml"