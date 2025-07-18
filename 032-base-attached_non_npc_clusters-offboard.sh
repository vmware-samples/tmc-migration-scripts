#!/bin/bash

MC_LIST_FOLDER=data/clusters
INPUT_CLUSTERS_FILE=$MC_LIST_FOLDER/attached_non_npc_clusters.yaml

#With the exported data, detach all the non-NPC attached clusters with the following command. Unhealthy attached clusters will try to be forcefully detached.

# Iterate through clusters
index=0
total=$(yq '.clusters | length' $INPUT_CLUSTERS_FILE)

while [ "$index" -lt "$total" ]; do
    name=$(yq ".clusters[$index].fullName.name" $INPUT_CLUSTERS_FILE)
    health=$(yq ".clusters[$index].status.health" $INPUT_CLUSTERS_FILE)

    if [ "$health" == "HEALTHY" ]; then
        echo "Detaching healthy cluster $name normally"
        tanzu tmc cluster delete "$name" -m attached -p attached
    else
        echo "Detaching unhealthy cluster $name forcely"
        tanzu tmc cluster delete "$name" -m attached -p attached --force
    fi

    index=$((index + 1))
done