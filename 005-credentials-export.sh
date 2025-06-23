#!/bin/bash
# Resource: Credential(Accounts) (Under Administration)

DIR=credential
DATA_DIR=data

if [ -d $DIR ]; then
  rm -rf $DIR/*
fi

mkdir -p $DIR/$DATA_DIR

tanzu tmc account credential list -o yaml > "$DIR/$DATA_DIR/credentials.yaml"