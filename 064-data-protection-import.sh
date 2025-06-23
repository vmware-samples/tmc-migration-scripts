#!/bin/bash

set -e

ONBOARDED_CLUSTER_INDEX_FILE="clusters/onboared-clusters-name-index"
TEMPFILE=_temp_dp_file_$(date +%s)
DPDIR=data-protection-data
if [ ! -d "${DPDIR}" ]; then
    echo "Dir %{DPDIR} doesn't exist!"
    exit 1
fi

TANZU=tanzu
#DRYRUN="--dry-run"
DRYRUN=

function create_dp_resources() {
    local filename=$1
    local keyname=$2
    local dpcmd=$3
    local total=$(yq -r ".totalCount" ${DPDIR}/${filename})
    local idx=0
    if [[ "${total}" == "0" ]]; then
        echo "==> No data in ${filename}"
        return
    fi
    echo "************************************************************************"
    echo "Start loading ${filename}, total number is ${total}"
    echo "************************************************************************"
    while true; do
        echo "==> Loading ${idx}/${total} in ${filename} ......"
        # Do we need to delete '.meta'?
        local elem=$(yq -o json ".${keyname}[${idx}]" ${DPDIR}/${filename} | yq -o json 'del(.status)')
        if [[ "${elem}" == "null" ]]; then
            break
        fi
        echo ${elem} > ${TEMPFILE}
        cat ${TEMPFILE}
        # Don't stop even the command fails, creating duplicated resoure will be
        # handled by TMCSM
        ${TANZU} tmc data-protection ${dpcmd} create -f ${TEMPFILE} ${DRYRUN} || true
        idx=$((idx+1))
    done
}

function enable_dataprotection() {
    local filename=$1
    local scope=$2
    local total=$(yq ". | length" ${DPDIR}/${filename})
    local idx=0
    if [[ "${total}" == "0" ]]; then
        echo "==> No data in ${filename}"
        return
    fi
    echo "************************************************************************"
    echo "Start loading ${filename}, total number is ${total}"
    echo "************************************************************************"
    while true; do
        if [[ $idx -ge $total ]]; then
            break
        fi
        echo "==> Loading ${idx}/${total} in ${filename} ......"
        # Do we need to delete '.meta'?
        yq -o yaml ".[${idx}]" ${DPDIR}/${filename} | yq -o yaml 'del(.status)' > ${TEMPFILE}
        cat ${TEMPFILE}
        if [[ "${scope}" == "cluster" ]]; then
            fullname=$(yq '.fullName | .managementClusterName + "." + .provisionerName + "." + .clusterName' ${TEMPFILE})
            if ! grep -qxf "${fullname}" "$ONBOARDED_CLUSTER_INDEX_FILE"; then
                echo "Cluster ${fullname} doesn't exist, just skip it"
                idx=$((idx+1))
                continue
            fi
        fi
        # Don't stop even the command fails, creating duplicated resoure will be
        # handled by TMCSM
        ${TANZU} tmc data-protection enable -s ${scope} -f ${TEMPFILE} ${DRYRUN} || true
        idx=$((idx+1))
    done
}

# Load backup location for both org and clsuter
create_dp_resources "backup_location_org.yaml" "backupLocations" "backup-location"
# It seems we don't need create location for cluster, because clusters are in org already
#create_dp_resources "backup_location_cluster.yaml" "backupLocations" "backup-location"

# Load schedule
create_dp_resources "schedule.yaml" "schedules" "schedule"

# Load backup
create_dp_resources "backup.yaml" "backups" "backup"

# Load restore
create_dp_resources "restore.yaml" "restores" "restore"

# Enable dataprotection on clustergroups and clusters
enable_dataprotection "dataprotection_clustergroups.yaml" "clustergroup"
enable_dataprotection "dataprotection_clusters.yaml" "cluster"

rm -f ${TEMPFILE}
