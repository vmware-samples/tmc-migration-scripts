#!/bin/bash
# Resource: Proxy Configuration(Under Administration)

# this is the second script.
# The second script will create proxy resources on SM based on the template files.
# run 038-proxy-create-template.sh first and manually fill in the missing field values before run this script.

SCRIPT_DIR=$(dirname "$0")
DATA_DIR="$SCRIPT_DIR"/data/proxy
TEMPLATE_DIR=template

if [ ! -d $DATA_DIR ]; then
  echo "Nothing to do without directory $DATA_DIR, please backup data first"
  exit 0
fi

if [ ! -d $DATA_DIR/$TEMPLATE_DIR ]; then
  echo "Nothing to do without directory $DATA_DIR/$TEMPLATE_DIR, please generate template files with script 038-admin-proxy-create-template.sh"
  echo "Please fill in the missing values in each template file(proxy/template/*.yaml) manually."
  exit 0
fi

for file in "$DATA_DIR"/$TEMPLATE_DIR/*; do
  if [ -f "$file" ]; then
    echo "Create credential with file $file"
    tanzu tmc account credential create --file $file
    if [ $? -eq 0 ]; then
      echo "Successfully created the credential with file $file"
    fi
  fi
done
