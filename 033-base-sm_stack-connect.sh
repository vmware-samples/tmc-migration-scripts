#!/bin/bash

#export TMC_SELF_MANAGED_USERNAME=admin-user@customer.com
#export TMC_SELF_MANAGED_PASSWORD=Fake@Pass
#export TMC_SELF_MANAGED_DNS=tmc.tanzu.io
#export TMC_SM_CONTEXT=tmc-sm

# Clear context first.
tanzu context delete ${TMC_SM_CONTEXT}  -y

# Create a context.
tanzu tmc context create ${TMC_SM_CONTEXT} --endpoint ${TMC_SELF_MANAGED_DNS} -i pinniped --basic-auth
