#! /bin/bash

source utils/log.sh

log "************************************************************************"
log "* Import Policy Templates to TMC SM ..."
log "************************************************************************"

DIR="policies/templates"
TEMP_DIR=$(mktemp -d)

src_templates="$DIR/templates.yaml"
templates_temp_dir="$TEMP_DIR/templates"
mkdir -p $templates_temp_dir
total_count=$(yq e '.templates | length' $src_templates)
for ((i=0; i < $total_count; i++))
do
    name=$( yq e ".templates[$i].fullName.name" $src_templates)
    if [[ "$name" =~ ^(tmc-|vmware-tmc-system-) ]]; then
        log info "[SKIP] system template:$name"
        continue
    fi

    object_file="$templates_temp_dir/${name}_object.yaml"
    yq e ".templates[$i].spec.object" $src_templates > $object_file
    description=$(yq e ".templates[$i].meta.description" $src_templates)
    inventory=$(yq e ".templates[$i].spec.dataInventory[]|[.group, .kind, .version]|@csv" $src_templates | sed 's/,/\//g' | sed ':a; N; $!ba; s/\n/,/g')

    tanzu tmc policy policy-template  create --object-file $object_file --description "$description" --data-inventory $inventory
done
