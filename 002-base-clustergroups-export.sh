#!/bin/bash
# Resource: Cluster group

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DATA_DIR="$SCRIPT_DIR"/data/clustergroup

if [ -d $DATA_DIR ]; then
  rm -rf $DATA_DIR/*
fi
mkdir -p $DATA_DIR

echo "************************************************************************"
echo "* Exporting ClusterGroups from TMC SaaS ..."
echo "************************************************************************"

tanzu tmc clustergroup list -o yaml > "$DATA_DIR/clustergroups.yaml"

echo "Exported ClusterGroups from TMC SaaS"