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

for clusterGroup in $clusterGroupList; do
  name=$(echo "$clusterGroup" | jq -r ".fullName.name")
  echo "Create clustergroup - $name"
  echo "$clusterGroup" | \
    jq -r 'del(.fullName.orgId, .meta.annotations, .meta.parentReferences)' | \
    tanzu tmc clustergroup create --file -
done
