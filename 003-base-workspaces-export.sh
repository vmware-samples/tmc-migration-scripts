#!/bin/bash
# Resource: Workspace

DIR=workspace
DATA_DIR=data

if [ -d $DIR ]; then
  rm -rf $DIR/*
fi

mkdir -p $DIR/$DATA_DIR

tanzu tmc workspace list -o yaml > "$DIR/$DATA_DIR/workspaces.yaml"