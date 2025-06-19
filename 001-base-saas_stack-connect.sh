#!/bin/bash

# export TANZU_API_TOKEN=<CSP-TOKEN>
# export ORG_NAME=tanzumissioncontroluserorgstg


## Create CLI context.
tanzu context create migration --type tmc --endpoint $ORG_NAME.tmc.tanzu.broadcom.com:443


## Alternative option:
## Exchange the access token.
#export TOKEN_URL=https://console.tanzu.broadcom.com/csp/gateway/am/api/auth/api-tokens/authorize
#export REFRESH_TOKEN=<CSP Token>

#export TMC_ACCESS_TOKEN="$(curl -X POST $TOKEN_URL \
#  -H 'Content-Type: application/x-www-form-urlencoded' \
#  -d "refresh_token=$REFRESH_TOKEN" | jq .access_token)"

#echo $TMC_ACCESS_TOKEN
