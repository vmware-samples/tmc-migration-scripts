#!/bin/bash
# Resource: Local Image Registry (Under Administration)

# This is the first script to generate template files without credentials

# The first script will generate template files under the folder: image-registry/template.
# Then users need to fill in the missing fields such as CA, credentials.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DATA_DIR="$SCRIPT_DIR"/data/image-registry
TEMPLATE_DIR=template
credential_type_json_template='{"type":{"kind":"Credential","version":"v1alpha1","package":"vmware.tanzu.manage.v1alpha1.account.credential.Credential"}}'
authenticated_data_json_template='{"keyValue":{"data":{".dockerconfigjson":"","ca-cert":""},"type":"DOCKERCONFIGJSON_SECRET_TYPE"}}'
unauthenticated_data_json_template='{"keyValue":{"data":{"registry-url":""}}}'

if [ ! -d $DATA_DIR ]; then
  echo "Nothing to do without directory $DATA_DIR, please backup data first"
  exit 0
fi

if [ ! -d $DATA_DIR/$TEMPLATE_DIR ]; then
  mkdir -p $DATA_DIR/$TEMPLATE_DIR
fi

echo "Generate image registry template yaml files"

imageRegistryList=$(cat $DATA_DIR/image-registries.yaml | yq eval -o=json - | jq -c '.credentials[]')

while IFS= read -r imageRegistry; do
  name=$(echo "$imageRegistry" | jq -r '.fullName.name // ""')
  registryUrl=$(echo "$imageRegistry" | jq -r '.meta.annotations."tmc.cloud.vmware.com/registry-url" // ""' | base64)
  registryNamespace=$(echo "$imageRegistry" | jq -r '.meta.annotations."registry-namespace" // ""')
  registryType=$(echo "$imageRegistry" | jq -r '.meta.annotations."tmc.cloud.vmware.com/registry-type" // ""')

  spec_data=$authenticated_data_json_template
  if [ "$registryType" != "authenticated" ]; then
    spec_data=`echo $unauthenticated_data_json_template | \
      jq --arg registryUrl "$registryUrl" '.keyValue.data."registry-url" = $registryUrl'`
  fi

  echo "$imageRegistry" | \
    jq 'del(.fullName.orgId, .meta.parentReferences, .meta.creationTime, .meta.generation, .meta.resourceVersion, .meta.updateTime, .meta.uid, .type, .status)' | \
    jq --argjson typeJson "$credential_type_json_template" '. += $typeJson'  | \
    jq --argjson new_data "$spec_data" '.spec.data = $new_data' | \
    jq --argjson new_annotations "{\"registry-namespace\":\"$registryNamespace\"}" '.meta.annotations = $new_annotations' | \
    yq eval -P -  > "$DATA_DIR/$TEMPLATE_DIR/${name}.yaml"
done <<< "$imageRegistryList"

echo '''
Template examples:

1.Spec Format for Image registry without username and password
##################################################################
spec:
  capability: IMAGE_REGISTRY
  data:
    keyValue:
      data:
        registry-url: <registry-url in base64 string>
  meta:
    provider: GENERIC_KEY_VALUE
    temporaryCredentialSupport: false


2.Spec Format for Image registry with username and password
##################################################################
spec:
  capability: IMAGE_REGISTRY
  data:
    keyValue:
      data:
        .dockerconfigjson: "<base64 string or call ./utils/create-docker-config-json-base64.sh to generate base64 string>"
        ca-cert: "<base64 string or remove key/value if not needed >"
      type: DOCKERCONFIGJSON_SECRET_TYPE
  meta:
    provider: GENERIC_KEY_VALUE
    temporaryCredentialSupport: false
'''

echo "##################################################################"
echo "The generated template files are without credentials."
echo "You need to go to the dir: data/image-registry/template to fill the missing field values for each template file before execute the import script."