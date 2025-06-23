#!/bin/bash
# Resource: Cluster group

DIR=clustergroup
DATA_DIR=data

if [ -d $DIR ]; then
  rm -rf $DIR/*
fi
mkdir -p $DIR/$DATA_DIR

tanzu tmc clustergroup list -o yaml > "$DIR/$DATA_DIR/clustergroups.yaml"