#!/bin/bash
# Resource: Role (Under Administration)

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DATA_DIR="$SCRIPT_DIR"/data/role

if [ ! -d $DATA_DIR ]; then
  echo "Nothing to do without directory $DATA_DIR, please backup data first"
  exit 0
fi

echo "************************************************************************"
echo "* Importing Customized Roles into TMC SM ..."
echo "************************************************************************"

role_type_json_template='{"type":{"kind":"Role","version":"v1alpha1","package":"vmware.tanzu.manage.v1alpha1.iam.role.Role"}}'

roleList=$(cat $DATA_DIR/roles.yaml | yq eval -o=json - | jq -c '.roles[]')

while IFS= read -r role; do
  if [[ -z "$role" ]]; then
    echo "No any customized role found"
  fi
  if [[ -n "$role" ]]; then
    name=$(echo "$role" | jq -r '.fullName.name // ""')
    echo "Create role $name"
    echo "$role" | \
      jq 'del(.fullName.orgId, .meta.parentReferences, .type)' | \
      jq --argjson typeJson "$role_type_json_template" '. += $typeJson'  | \
      tanzu tmc iam role create --file -
  fi
done <<< "$roleList"

echo "Imported Customized Roles into TMC SM ..."