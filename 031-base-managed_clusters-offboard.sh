#!/bin/bash

# Keep the raw data of all management clusters.
# Process the data before using it later.

mkdir -p clusters && tanzu tmc mc list -o yaml > clusters/mc_list.yaml

#Export all the managed workload clusters under each management cluster.
tanzu tmc mc list | tail -n +2 | while read name; do tanzu tmc cluster list -o yaml -m "$name" > "clusters/wc_of_$name.yaml"; done


#Unmanage all the workload clusters under the management cluster before deregister.
tanzu tmc mc list | tail -n +2 | while read -r name; do
  echo "Unmanaging workload clusters under mc $name"
  tanzu tmc cluster list -m "$name" | tail -n +2 | awk '{print $1, $2, $3}' | while read wc_name mgmt prov; do
    echo "Unmanging workload cluster $wc_name$"
    tanzu tmc mc wc unmanage "$wc_name" -m "$mgmt" -p "$prov"
  done
done

# Deregister the management cluster.
# For each management cluster returned by `tanzu tmc mc list | tail -n +2`
if [ -z "$(tanzu tmc cluster list -m "$mc_name" | tail -n +2)" ]; then
  tanzu tmc mc deregister "$mc_name"
fi