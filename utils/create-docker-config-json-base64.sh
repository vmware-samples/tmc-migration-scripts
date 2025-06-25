#!/bin/bash
# Resource: Local Image Registry (Under Administration)

# This is the script to generate docker config json with base64 encoded format

username=${1-} # username
password=${2-} # password
registryUrl=${3-}

if [ -z "$username" ]; then
  echo "Registry username as first param is missing".
  exit 1
fi

if [ -z "$password" ]; then
  echo "Registry password as second param is missing".
  exit 1
fi

if [ -z "$registryUrl" ]; then
  echo "Registry Url as third param is missing".
  exit 1
fi

data="{\"auths\":{\"$registryUrl\":{\"username\":\"$username\",\"password\":\"$password\"}}}"

echo $data | base64