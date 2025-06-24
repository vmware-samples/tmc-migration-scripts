#! /bin/bash

source utils/log.sh

log "************************************************************************"
log "* Exporting Policy Templates from TMC SaaS ..."
log "************************************************************************"

DIR="policies/templates"
mkdir -p $DIR

log info "Exporting policy templates ..."
tanzu tmc policy policy-template list -o yaml > $DIR/templates.yaml