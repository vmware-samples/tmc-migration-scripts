#!/bin/bash
# Resource: Local Image Registry (Under Administration)

# This is the script to generate docker config json with base64 encoded format

accessId=${1-}
accessSecret=${2-}
registryUrl=${3-}

if [ -z "$accessId" ]; then
  echo "accessId as first param is missing".
  exit 1
fi

if [ -z "$accessSecret" ]; then
  echo "accessSecret as second param is missing".
  exit 1
fi

if [ -z "$registryUrl" ]; then
  echo "registryUrl as third param is missing".
  exit 1
fi

data="{\"auths\":{\"$registryUrl\":{\"username\":\"$accessId\",\"password\":\"$accessSecret\"}}}"

echo $data | base64