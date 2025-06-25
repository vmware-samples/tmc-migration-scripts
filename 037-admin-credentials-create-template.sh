#!/bin/bash
# Resource: Credential(Accounts) (Under Administration)

# This is the first script(037-admin-credentials-create-template.sh) to generate template files without credentials

# The first script will generate template files under the folder: credential/template.
# Then users need to fill in the missing fields such as CA, credentials.

SCRIPT_DIR=$(dirname "$0")
DATA_DIR="$SCRIPT_DIR"/data/credential
TEMPLATE_DIR=template
credential_type_json_template='{"type":{"kind":"Credential","version":"v1alpha1","package":"vmware.tanzu.manage.v1alpha1.account.credential.Credential"}}'

if [ ! -d $DATA_DIR ]; then
  echo "Nothing to do without directory $DATA_DIR, please backup data first"
  exit 0
fi

if [ ! -d $DATA_DIR/$TEMPLATE_DIR ]; then
  mkdir -p $DATA_DIR/$TEMPLATE_DIR
fi

echo "Generate template yaml files for credentials with script 037-admin-credentials-create-template.sh"

# Handle with IMAGE_REGISTRY and PROXY_CONFIG in another script
# No longer support the AZURE_AKS and AWS_EKS.
credentialList=`cat "$DATA_DIR/credentials.yaml" | \
  yq eval -o=json - | jq '.' | \
  jq 'del(.totalCount)' | \
  jq '.credentials |=map(select(.spec.capability != "IMAGE_REGISTRY" and .spec.capability != "PROXY_CONFIG" and .spec.meta.provider != "AZURE_AKS" and .spec.meta.provider != "AWS_EKS"))' | \
  jq -c '.credentials[]'`

while IFS= read -r credential; do
  name=$(echo "$credential" | jq -r '.fullName.name // ""')
  provider=$(echo "$credential" | jq -r '.spec.meta.provider // ""')
  capability=$(echo "$credential" | jq -r '.spec.capability // ""')

  if [ "$provider" = "GENERIC_S3" ]; then
    echo "$credential" | \
      jq 'del(.fullName.orgId, .meta.parentReferences, .meta.creationTime, .meta.generation, .meta.resourceVersion, .meta.annotations, .meta.updateTime, .meta.uid, .type, .status)' | \
      jq --argjson typeJson "$credential_type_json_template" '. += $typeJson'  | \
      jq --argjson data "{\"aws_access_key_id\":\"\",\"aws_secret_access_key\":\"\"}" '.spec.data.keyValue.data += $data'  | \
      yq eval -P -  > "$DIR/$TEMPLATE_DIR/${provider}--${name}.yaml"
  elif [ "$provider" = "AWS_EC2" ] || [ "$provider" = "AZURE_AD" ]; then
    echo "$credential" | \
      jq 'del(.fullName.orgId, .meta.parentReferences, .meta.creationTime, .meta.generation, .meta.resourceVersion, .meta.annotations, .meta.updateTime, .meta.uid, .type, .status)' | \
      jq --argjson typeJson "$credential_type_json_template" '. += $typeJson'  | \
      yq eval -P -  > "$DIR/$TEMPLATE_DIR/${provider}--${name}.yaml"
  fi
done  <<< "$credentialList"

echo '''
Template examples:

1.Spec Format for Self-provisioned: AWS S3 or S3 compatible
##################################################################
spec:
  capability: DATA_PROTECTION
  data:
    keyValue:
      data:
        aws_access_key_id: "<Your aws_access_key_id>"
        aws_secret_access_key: "<Your aws_secret_access_key>"
      type: SECRET_TYPE_UNSPECIFIED
  meta:
    provider: GENERIC_S3
    temporaryCredentialSupport: false

2.Spec Format for Self-provisioned: Azure Blob
##################################################################

spec:
  capability: DATA_PROTECTION
  data:
    azureCredential:
      servicePrincipal:
        azureCloudName: <AzurePublicCloud | AzureUSGovernmentCloud | AzureChinaCloud | AzureGermanCloud>
        clientId: <Your clientId>
        clientSecret: <Your clientSecret>
        resourceGroup: <Your resource group>
        subscriptionId: <Your subscriptionId>
        tenantId: <Your tenantId>
  meta:
    provider: AZURE_AD
    temporaryCredentialSupport: false

3.Spec Format for Self-provisioned: AWS_EC2
##################################################################
spec:
  capability: DATA_PROTECTION
  data:
    awsCredential:
      accountId: "<Your accountId or empty string>"
      iamRole:
        arn: "<Your arn>"
        extId: "<Your extId>"
  meta:
    provider: AWS_EC2
    temporaryCredentialSupport: false
'''

echo "##################################################################"
echo "You need to go to the dir: data/credential/template to fill the missing fields for each template file before execute the import script."