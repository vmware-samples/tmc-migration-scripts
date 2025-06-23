#!/bin/bash
# Resource: Role (Under Administration)

DIR=role
DATA_DIR=data

if [ ! -d $DIR ]; then
  echo "Nothing to do without directory $DIR, please backup data first"
  exit 0
fi

role_type_json_template='{"type":{"kind":"Role","version":"v1alpha1","package":"vmware.tanzu.manage.v1alpha1.iam.role.Role"}}'

roleList=$(cat $DIR/$DATA_DIR/roles.yaml | yq eval -o=json - | jq -c '.roles[]')

while IFS= read -r role; do
  name=$(echo "$role" | jq -r '.fullName.name // ""')
  echo "Create role $name"
  echo "$role" | \
    jq 'del(.fullName.orgId, .meta.parentReferences, .type)' | \
    jq --argjson typeJson "$role_type_json_template" '. += $typeJson'  | \
    tanzu tmc iam role create --file -
done <<< "$roleList"