#!/bin/bash
# Resource: Workspace

DIR=workspace
DATA_DIR=data

if [ ! -d $DIR ]; then
  echo "Nothing to do without directory $DIR, please backup data first"
  exit 0
fi

workspaceList=`cat $DIR/$DATA_DIR/workspaces.yaml | yq eval -o=json - | jq '.' | \
  jq -c '.workspaces[]'`

for workspace in $workspaceList; do
  name=$(echo "$workspace" | jq -r ".fullName.name")
  echo "Create workspace - $name"
  echo "$workspace" | \
    jq -r 'del(.fullName.orgId, .meta.annotations, .meta.parentReferences)' | \
    tanzu tmc workspace create --file -
done
