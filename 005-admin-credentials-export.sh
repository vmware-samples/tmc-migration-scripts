#!/bin/bash
# Resource: Credential(Accounts) (Under Administration)

DATA_DIR=data/credential

if [ -d $DATA_DIR ]; then
  rm -rf $DATA_DIR/*
fi

mkdir -p $DATA_DIR

tanzu tmc account credential list -o yaml > "$DATA_DIR/credentials.yaml"