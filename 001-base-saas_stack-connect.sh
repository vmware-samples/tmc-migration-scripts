#!/bin/bash

# export TANZU_API_TOKEN=<CSP-TOKEN>
# export ORG_NAME=tanzumissioncontroluserorgstg
# export TANZU_CLI_CEIP_OPT_IN_PROMPT_ANSWER=no


## Create CLI context.
export TMC_CONTEXT=migration

# Clear the context first if it exists.
tanzu context delete ${TMC_CONTEXT} -y

# For production.
#tanzu context create ${TMC_CONTEXT} --type tmc --endpoint $ORG_NAME.tmc.tanzu.broadcom.com:443

tanzu config eula accept
# For experiments.
tanzu context create ${TMC_CONTEXT} --type tmc --staging --endpoint $ORG_NAME.tmc-dev.tanzu.broadcom.com:443


## Alternative option:
## Exchange the access token.
#export TOKEN_URL=https://console.tanzu.broadcom.com/csp/gateway/am/api/auth/api-tokens/authorize
#export REFRESH_TOKEN=<CSP Token>

export TMC_ACCESS_TOKEN="$(curl -X POST $TOKEN_URL \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "refresh_token=$REFRESH_TOKEN" | jq .access_token)"

echo $TMC_ACCESS_TOKEN
