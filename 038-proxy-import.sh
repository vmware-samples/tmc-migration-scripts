#!/bin/bash
# Resource: Proxy Configuration(Under Administration)

# this is the second script.
# The second script will create proxy resources on SM based on the template files.
# run 038-proxy-create-template.sh first and manually fill in the missing field values before run this script.

DIR=proxy
DATA_DIR=data
TEMPLATE_DIR=template

if [ ! -d $DIR ]; then
  echo "Nothing to do without directory $DIR, please backup data first"
  exit 0
fi

if [ ! -d $DIR/$TEMPLATE_DIR ]; then
  echo "Nothing to do without directory $DIR/$TEMPLATE_DIR, please generate template files first"
  exit 0
fi

for file in "$DIR"/$TEMPLATE_DIR/*; do
  if [ -f "$file" ]; then
    echo "Create credential with file $file"
    tanzu tmc account credential create --file $file
    if [ $? -eq 0 ]; then
      echo "Successfully created the credential with file $file"
    fi
  fi
done
