#!/bin/bash
# Resource: Workspace

DATA_DIR=data/workspace

if [ -d $DATA_DIR ]; then
  rm -rf $DATA_DIR/*
fi

mkdir -p $DATA_DIR

tanzu tmc workspace list -o yaml > "$DATA_DIR/workspaces.yaml"