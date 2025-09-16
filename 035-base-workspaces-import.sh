#!/bin/bash
# Resource: Workspace

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DATA_DIR="$SCRIPT_DIR"/data/workspace
INTERVAL=2

if [ ! -d $DATA_DIR ]; then
  echo "Nothing to do without directory $DATA_DIR, please backup data first"
  exit 0
fi

echo "************************************************************************"
echo "* Importing Workspaces into TMC SM ..."
echo "************************************************************************"

workspaceList=`cat $DATA_DIR/workspaces.yaml | yq eval -o=json - | jq '.' | \
  jq -c '.workspaces[]'`

while IFS= read -r workspace; do
  if [[ -z "$workspace" ]]; then
    echo "No any workspace found"
  fi
  if [[ -n "$workspace" ]]; then
    name=$(echo "$workspace" | jq -r ".fullName.name")
    if [[ "$name" != "default" ]]; then
      echo "Create workspace - $name"
      echo "$workspace" | \
        jq -r 'del(.fullName.orgId, .meta.annotations, .meta.parentReferences)' | \
        tanzu tmc workspace create --file -
      sleep $INTERVAL
    fi
  fi
done <<< "$workspaceList"

echo "Imported Workspaces into TMC SM ..."