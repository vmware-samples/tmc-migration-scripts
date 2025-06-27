#!/bin/bash

curl_api_call() {
  local method="GET"
  local data=""
  local url=""

  # Parse flags
  while [[ $# -gt 0 ]]
  do
    opt=${1:-""}
    case $opt in
      -X) method="$2"; shift 2;;
      -d) data="$2"; shift 2;;
      *) url="$1"; shift;;
    esac
  done
  
  if [ -z "$url" ]; then
    echo "Usage: curl_api_call [-X METHOD] [-d DATA] <URL>"
    return 1
  fi

  # Get the token
  tanzu tmc clustergroup get default >/dev/null && eval $(tanzu context get tmc-sm | yq -r '.globalOpts.auth | "export TMC_SM_ACCESS_TOKEN=\"\(.accessToken)\"; export TMC_SM_ID_TOKEN=\"\(.IDToken)\";"' )
  
  # Get DNS zone
  export TMC_SM_ENDPOINT=$(tanzu context get tmc-sm | yq -r '.globalOpts.auth.issuer' | sed -E 's|https://pinniped-supervisor\.([^/]+)/provider/pinniped|\1|')

  # Build base curl command
  local cmd="curl -X $method"
  cmd+=" -H \"Content-Type: application/json\""
  cmd+=" -H \"Authorization: Bearer $TMC_SM_ACCESS_TOKEN\""
  cmd+=" -H \"grpc-metadata-x-user-id: $TMC_SM_ID_TOKEN\""

  # Add data if provided
  if [ -n "$data" ]; then
    cmd+=" -d '$data'"
  fi

  # Add the URL
  cmd+=" \"https://$TMC_SM_ENDPOINT/$url\""

  eval "$cmd"
}
