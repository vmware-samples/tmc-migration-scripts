#!/bin/bash
# Resource: Proxy Configuration(Under Administration)

# This is the first script to generate template files without credentials

# The first script will generate template files under the folder: proxy/template.
# Then users need to fill in the missing fields such as CA, credentials.

DATA_DIR=data/proxy
TEMPLATE_DIR=template
credential_type_json_template='{"type":{"kind":"Credential","version":"v1alpha1","package":"vmware.tanzu.manage.v1alpha1.account.credential.Credential"}}'
proxy_data_json_template='{"httpUserName": "","httpPassword": "","httpsUserName": "","httpsPassword": "","proxyCABundle": ""}'

if [ ! -d $DATA_DIR ]; then
  echo "Nothing to do without directory $DATA_DIR, please backup data first"
  exit 0
fi

if [ ! -d $DATA_DIR/$TEMPLATE_DIR ]; then
  mkdir -p $DATA_DIR/$TEMPLATE_DIR
fi

echo "Generate proxy configuration template yaml files"

proxyList=$(cat $DATA_DIR/proxies.yaml | yq eval -o=json - | jq -c '.credentials[]')

while IFS= read -r proxy; do
  name=$(echo "$proxy" | jq -r '.fullName.name // ""')
  echo "$proxy" | \
    jq 'del(.fullName.orgId, .meta.parentReferences, .meta.annotations."x-customer-domain", .type, .status)' | \
    jq --argjson typeJson "$credential_type_json_template" '. += $typeJson'  | \
    jq --argjson new_data "$proxy_data_json_template" '.spec.data.keyValue.data = $new_data' | \
    yq eval -P -  > "$DIR/$TEMPLATE_DIR/${name}.yaml"
done <<< "$proxyList"

echo '''
Template examples:

1.Spec Format for Proxy
##################################################################
spec:
  capability: PROXY_CONFIG
  data:
    keyValue:
      data:
        httpUserName: "<base64 string>"
        httpPassword: "<base64 string>"
        httpsUserName: "<base64 string>"
        httpsPassword: "<base64 string>"
        proxyCABundle: "<base64 string>"
      type: SECRET_TYPE_UNSPECIFIED
  meta:
    provider: PROVIDER_UNSPECIFIED
    temporaryCredentialSupport: false
'''

echo "##################################################################"
echo "The generated template files are without credentials."
echo "You need to go to the dir: data/proxy/template to fill the missing field values for each template file before execute the import script."