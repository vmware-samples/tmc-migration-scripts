#!/bin/bash
# Resource: Workspace

SCRIPT_DIR=$(dirname "$0")
DATA_DIR="$SCRIPT_DIR"/data/workspace

if [ -d $DATA_DIR ]; then
  rm -rf $DATA_DIR/*
fi

mkdir -p $DATA_DIR

tanzu tmc workspace list -o yaml > "$DATA_DIR/workspaces.yaml"