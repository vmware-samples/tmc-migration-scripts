#!/bin/bash

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

source $SCRIPT_DIR/log.sh

# The CSP_URL can be overridden by environment variable, e.g for stg CSP
#  export CSP_URL=https://console-stg.tanzu.broadcom.com/csp/gateway/am/api/auth/api-tokens/authorize
if [ -z "$CSP_URL" ]; then
  CSP_URL="https://console.tanzu.broadcom.com/csp/gateway/am/api/auth/api-tokens/authorize"
fi

if [ -z "$TANZU_API_TOKEN" ] || [ -z "$
ORG_NAME" ]; then
  log error "Environment variables TANZU_API_TOKEN and ORG_NAME are required"
  exit 1
fi

# The URL can be overridden by environment variable, e.g for dev stack
# export TMC_ENDPOINT={{ORG_NAME}}.tmc-dev.tanzu.broadcom.com
if [ -z "$TMC_ENDPOINT" ]; then
  TMC_ENDPOINT="${ORG_NAME}.tanzu.broadcom.com"
fi

curl_api_call() {
  local method="GET"
  local data=""
  local url=""

  # Parse flags
  while getopts "X:d:" opt; do
    case $opt in
      X) method="$OPTARG" ;;
      d) data="$OPTARG" ;;
      \?) echo "Invalid option: -$OPTARG" >&2; return 1 ;;
    esac
  done
  shift $((OPTIND -1))  # Shift to get the positional URL argument

  url="$1"
  if [ -z "$url" ]; then
    log error "Usage: curl_api_call [-X METHOD] [-d DATA] <URL>"
    return 1
  fi

  # Get access token
  ATTEMPTS=10 # it does not always succeed to fetch the access token
  for ((i=0; i < $ATTEMPTS; i++));
  do
    local access_token=$(curl -X POST "$CSP_URL?refresh_token=$TANZU_API_TOKEN" \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -d "refresh-token=$TANZU_API_TOKEN" \
    | jq -r '.access_token')

    if [[ "$access_token" != "null" ]]; then
      break
    fi
    sleep 2;
  done

  if [[ "$access_token" == "null" ]]; then
    log error "Failed to get API acess token"
    return 1
  fi

  # Build base curl command
  local cmd="curl -X $method"
  cmd+=" -H \"Content-Type: application/json\""
  cmd+=" -H \"Authorization: Bearer $access_token\""

  # Add data if provided
  if [ -n "$data" ]; then
    cmd+=" -d '$data'"
  fi

  # Add the URL
  cmd+=" \"https://$TMC_ENDPOINT/$url\""

  eval "$cmd"
}
