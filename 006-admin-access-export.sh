#!/bin/bash
# Resource: Access (Under Administration)

DATA_DIR=data/credential-access

if [ -d $DATA_DIR ]; then
  rm -rf $DATA_DIR/*
fi

mkdir -p $DATA_DIR

tmc_curl() {
  tmcInfo=`tanzu context get migration | yq eval -o=json - | jq -c '.'`
  TMC_ENDPOINT=`echo $tmcInfo | jq -r '.globalOpts.endpoint'`
  TMC_ACCESS_TOKEN=`echo $tmcInfo | jq -r '.globalOpts.auth.accessToken'`
  echo `curl -H 'Content-Type: application/json' -H "Authorization: Bearer $TMC_ACCESS_TOKEN" "https://$TMC_ENDPOINT/v1alpha1/account/credentials:iam/$@"`
}

# No longer to support AZURE_AKS and AWS_EKS
credentialList=`tanzu tmc account credential list -o yaml | \
  yq eval -o=json - | jq '.' | \
  jq 'del(.totalCount)' | \
  jq '.credentials |=map(select(.spec.meta.provider != "AZURE_AKS" and .spec.meta.provider != "AWS_EKS"))' | \
  jq -c '.credentials[]'`

while IFS= read -r credential; do
 name=$(echo "$credential" | jq -r '.fullName.name // ""')
 tmc_curl ${name} |jq '.' | yq eval -P - > $DATA_DIR/access---${name}.yaml
done  <<< "$credentialList"