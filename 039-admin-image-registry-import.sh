#!/bin/bash
# Resource: Local Image Registry (Under Administration)

# this is the second script.
# The second script will create proxy resources on SM based on the template files.
# run 039-image-registry-create-template.sh first and manually fill in the missing field values before run this script.

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DATA_DIR="$SCRIPT_DIR"/data/image-registry
TEMPLATE_DIR=template

if [ ! -d $DATA_DIR ]; then
  echo "Nothing to do without directory $DATA_DIR, please backup data first"
  exit 0
fi

echo "************************************************************************"
echo "* Importing Image Registry into TMC SM ..."
echo "************************************************************************"

if [ ! -d $DATA_DIR/$TEMPLATE_DIR ]; then
  echo "Nothing to do without directory $DATA_DIR/$TEMPLATE_DIR, please generate template files first"
  echo "Please fill in the missing values in each template file(image-registry/template/*.yaml) manually."
  exit 0
fi

for file in "$DATA_DIR"/$TEMPLATE_DIR/*; do
  if [ -f "$file" ]; then
    echo "Create image registry with file $file"
    tanzu tmc account credential create --file $file
    if [ $? -eq 0 ]; then
      echo "Successfully created the image registry with file $file"
    fi
  fi
done

echo "Imported Image Registry into TMC SM ..."