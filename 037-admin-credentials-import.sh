#!/bin/bash
# Resource: Credential(Accounts) (Under Administration)

# this is the second script.
# The second script will create credential resources on SM based on the template files.
# run 037-credentials-create-template.sh first and manually fill in the missing field values before run this script.

SCRIPT_DIR=$(dirname "$0")
DATA_DIR="$SCRIPT_DIR"/data/credential
TEMPLATE_DIR=template

if [ ! -d $DATA_DIR ]; then
  echo "Nothing to do without directory $DATA_DIR, please backup data first"
  exit 0
fi

if [ ! -d $DATA_DIR/$TEMPLATE_DIR ]; then
  echo "Nothing to do without directory $DATA_DIR/$TEMPLATE_DIR, please generate template files first"
  echo "Please fill in the missing values in each template file(credential/template/*.yaml) manually."
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