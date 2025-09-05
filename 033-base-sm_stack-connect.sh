#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")"/utils/log.sh

#export TMC_SELF_MANAGED_USERNAME=admin-user@customer.com
#export TMC_SELF_MANAGED_PASSWORD=Fake@Pass
#export TMC_SELF_MANAGED_DNS=tmc.tanzu.io

# If MFA is enabled for the IDP, export this environment variable.
#export TMC_SM_IDP_MFA_ENABLED=true

# Check if all required environment variables are set.
if [ -z "$TMC_SELF_MANAGED_USERNAME" ]; then
  log error "❌ TMC_SELF_MANAGED_USERNAME environment variable is not set."
  exit 1
fi

if [ -z "$TMC_SELF_MANAGED_PASSWORD" ]; then
  log error "❌ TMC_SELF_MANAGED_PASSWORD environment variable is not set."
  exit 1
fi

if [ -z "$TMC_SELF_MANAGED_DNS" ]; then
  log error "❌ TMC_SELF_MANAGED_DNS environment variable is not set."
  exit 1
fi

TMC_SM_CONTEXT="tmc-sm"

# Clear context first.
tanzu context delete ${TMC_SM_CONTEXT}  -y

# Create a context.
if [[ $TMC_SM_IDP_MFA_ENABLED == "true" ]]; then
    echo "The IDP MFA is enabled. Please follow the guide to open the URL in a browser and complete the authentication process."
    tanzu tmc context create ${TMC_SM_CONTEXT} --endpoint ${TMC_SELF_MANAGED_DNS} -i pinniped
else
    tanzu tmc context create ${TMC_SM_CONTEXT} --endpoint ${TMC_SELF_MANAGED_DNS} -i pinniped --basic-auth
fi
