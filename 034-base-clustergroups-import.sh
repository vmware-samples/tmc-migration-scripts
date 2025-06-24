#!/bin/bash
# Resource: Cluster group

DIR=clustergroup
DATA_DIR=data

if [ ! -d $DIR ]; then
  echo "Nothing to do without directory $DIR, please backup data first"
  exit 0
fi

clusterGroupList=`cat $DIR/$DATA_DIR/clustergroups.yaml | yq eval -o=json - | jq '.' | \
  jq -c '.clusterGroups[]'`

while IFS= read -r clusterGroup; do
  if [[ -z "$clusterGroup" ]]; then
    echo "No any clustergroup found"
  fi
  if [[ -n "$clusterGroup" ]]; then
    name=$(echo "$clusterGroup" | jq -r ".fullName.name")
    if [[ "$name" != "default" ]]; then
      echo "Create clustergroup: $name"
      echo "$clusterGroup" | \
        jq -r 'del(.fullName.orgId, .meta.annotations, .meta.parentReferences)' | \
        tanzu tmc clustergroup create --file -
    fi
  fi
done <<< "$clusterGroupList"
