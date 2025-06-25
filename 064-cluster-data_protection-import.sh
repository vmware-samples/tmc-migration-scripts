#!/bin/bash

set +e

ONBOARDED_CLUSTER_INDEX_FILE="data/clusters/onboarded-clusters-name-index"
TEMPFILE=_temp_dp_file_$(date +%s)
DPDIR=data/data-protection
if [ ! -d "${DPDIR}" ]; then
    echo "Dir %{DPDIR} doesn't exist!"
    exit 1
fi

TANZU=tanzu
#DRYRUN="--dry-run"
DRYRUN=

function create_dp_resources() {
    local filename=$1
    if [ ! -f ${DPDIR}/${filename} ]; then
        echo "==> No file ${filename}"
        return
    fi
    local keyname=$2
    local dpcmd=$3
    local scope=$4
    local total=$(yq -r ".totalCount" ${DPDIR}/${filename})

    if [[ "${total}" == "0" ]]; then
        echo "==> No data in ${filename}"
        return
    fi
    echo "************************************************************************"
    echo "Start loading ${filename}, total number is ${total}"
    echo "************************************************************************"
    for ((idx = 0; idx < $total; idx += 1))
    do
        echo "==> Loading ${idx}/${total} in ${filename} ......"
        # Do we need to delete '.meta'?
        local elem=$(yq -o yaml ".${keyname}[${idx}]" ${DPDIR}/${filename} | yq -o yaml 'del(.status)')
        if [[ "${elem}" == "null" ]]; then
            break
        fi
        echo "${elem}" > ${TEMPFILE}
        cat ${TEMPFILE}
        # Don't stop even the command fails, creating duplicated resoure will be
        # handled by TMCSM
        SCOPE=""
        if [[ ${scope} != "" ]]; then
            SCOPE="-s ${scope}"
        fi
        for ((trynum = 0; trynum < 60; trynum += 1))
        do
            retmsg=$(${TANZU} tmc data-protection ${dpcmd} create ${SCOPE} -f ${TEMPFILE} ${DRYRUN} 2>&1)
            if [[ ${retmsg} != *"Data Protection has not been enabled for the cluster"* ]] && [[ ${retmsg} != *"is not yet available for backup"* ]]; then
                echo " ================== >>>>>>>>>>> ${retmsg}"
                break
            fi
            echo ${retmsg}
            echo "try again ${trynum}/10 ..."
            sleep 10
        done
    done
}

function enable_dataprotection() {
    local filename=$1
    if [ ! -f ${DPDIR}/${filename} ]; then
        echo "==> No file ${filename}"
        return
    fi
    local scope=$2
    local total=$(yq ". | length" ${DPDIR}/${filename})
    if [[ "${total}" == "0" ]]; then
        echo "==> No data in ${filename}"
        return
    fi
    echo "************************************************************************"
    echo "Start loading ${filename}, total number is ${total}"
    echo "************************************************************************"
    for ((idx = 0; idx < $total; idx += 1))
    do
        echo "==> Loading ${idx}/${total} in ${filename} ......"
        # Do we need to delete '.meta'?
        yq -o yaml ".[${idx}]" ${DPDIR}/${filename} | yq -o yaml 'del(.status)' > ${TEMPFILE}
        cat ${TEMPFILE}
        if [[ "${scope}" == "cluster" ]]; then
            fullname=$(yq '.fullName | .managementClusterName + "." + .provisionerName + "." + .clusterName' ${TEMPFILE})
            if ! grep -qx "${fullname}" "$ONBOARDED_CLUSTER_INDEX_FILE"; then
                echo "Cluster ${fullname} doesn't exist, just skip it"
                continue
            fi
        fi
        # Don't stop even the command fails, creating duplicated resoure will be
        # handled by TMCSM
        ${TANZU} tmc data-protection enable -s ${scope} -f ${TEMPFILE} ${DRYRUN} || true
    done
}

# Load backup location for both org and clsuter
create_dp_resources "backup_location_org.yaml" "backupLocations" "backup-location"
# It seems we don't need create location for cluster, because clusters are in org already
#create_dp_resources "backup_location_cluster.yaml" "backupLocations" "backup-location"

# Enable dataprotection on clustergroups and clusters
enable_dataprotection "dataprotection_clustergroups.yaml" "clustergroup"
enable_dataprotection "dataprotection_clusters.yaml" "cluster"

# Load schedule
create_dp_resources "schedule-clustergroup.yaml" "schedules" "schedule" "clustergroup"
create_dp_resources "schedule-cluster.yaml" "schedules" "schedule" "cluster"

# Load backup
create_dp_resources "backup.yaml" "backups" "backup" ""

# Load restore
create_dp_resources "restore.yaml" "restores" "restore" ""

rm -f ${TEMPFILE}
