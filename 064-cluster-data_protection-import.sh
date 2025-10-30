#!/bin/bash

set +e
source utils/kubeconfig.sh

ONBOARDED_CLUSTER_INDEX_FILE="data/clusters/onboarded-clusters-name-index"

TEMPFILE=/tmp/_temp_dp_file_$(date +%s)
TEMPKUBECONFIG=${TEMPFILE}_kubeconfig
DPDIR=data/data-protection
if [ ! -d "${DPDIR}" ]; then
    echo "Dir ${DPDIR} doesn't exist!"
    exit 1
fi

TANZU=tanzu
KUBECTL=kubectl
#DRYRUN="--dry-run"
DRYRUN=

# Support linux only, for MacOS, please use 'gsed' instead
echo "Updating orgId in files ......"
ORGID=$(${TANZU} tmc management-cluster get attached | yq ".fullName.orgId")
grep "orgId: " ${DPDIR}/* -r
find ${DPDIR} -name "*.yaml" -exec sed -i "s/orgId: .*/orgId: ${ORGID}/g" {} \;
grep "orgId: " ${DPDIR}/* -r

function create_dp_resources() {
    local filename=$1
    if [ ! -f ${DPDIR}/${filename} ]; then
        echo "==> No file ${filename}"
        return
    fi
    local keyname=$2
    local dpcmd=$3
    local scope=$4
    local total="0"
    if [[ "$scope" == "clustergroup" && "$keyname" == "schedules" ]]; then
        total=$(yq eval ". | length" ${DPDIR}/${filename})
    else
        total=$(yq -r ".totalCount" ${DPDIR}/${filename})
    fi

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
        local name=${keyname}
        if [[ "$keyname" == "schedules" && "$scope" == "clustergroup" ]]; then
            name=""
        fi

        local elem=$(yq -o yaml ".${name}[${idx}]" ${DPDIR}/${filename} | yq -o yaml 'del(.meta)' | yq -o yaml 'del(.status)')
        if [[ "${elem}" == "null" ]]; then
            break
        fi
        echo "${elem}" > ${TEMPFILE}
        cat ${TEMPFILE}
        if [[ "${dpcmd}" != "backup-location" ]] && [[ "${scope}" != "clustergroup" ]]; then
            # Just import cluster specific backup/schedule
            fullname=$(yq '.fullName | .managementClusterName + "." + .provisionerName + "." + .clusterName' ${TEMPFILE})
            if ! grep -qx "${fullname}" "$ONBOARDED_CLUSTER_INDEX_FILE"; then
                echo "Cluster ${fullname} doesn't exist, just skip it"
                continue
            fi
        fi
        # Don't stop even the command fails, creating duplicated resoure will be
        # handled by TMCSM
        SCOPE=""
        if [[ ${scope} != "" ]]; then
            SCOPE="-s ${scope}"
        fi
        for ((trynum = 0; trynum < 60; trynum += 1))
        do
            retmsg=$(${TANZU} tmc data-protection ${dpcmd} create ${SCOPE} -f ${TEMPFILE} ${DRYRUN} 2>&1)
            if [[ ${retmsg} == *"code = AlreadyExists"* ]]; then
                retmsg=$(${TANZU} tmc data-protection ${dpcmd} update ${SCOPE} -f ${TEMPFILE} ${DRYRUN} 2>&1)
                echo "==> update: ${retmsg}"
                break
            elif [[ ${retmsg} != *"Data Protection has not been enabled for the cluster"* ]] && [[ ${retmsg} != *"is not yet available for backup"* ]]; then
                echo "==> error: ${retmsg}"
                break
            else
                echo "==> message: ${retmsg}"
            fi
            echo "try again ${trynum}/60 ..."
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
        yq -o yaml ".[${idx}]" ${DPDIR}/${filename} | yq -o yaml 'del(.spec.backupLocationNames)' | yq -o yaml 'del(.status)' > ${TEMPFILE}
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

function create_old_bsl() {
    local filename=$1
    if [ ! -f ${DPDIR}/${filename} ]; then
        echo "==> No file ${filename}"
        return
    fi
    local total=$(yq -r ".totalCount" ${DPDIR}/${filename})

    if [[ "${total}" == "0" ]]; then
        echo "==> No data in ${filename}"
        return
    fi
    echo "************************************************************************"
    echo "Start creating bsl in ${filename}, total number is ${total}"
    echo "************************************************************************"
    for ((idx = 0; idx < $total; idx += 1))
    do
        echo "==> Loading ${idx}/${total} in ${filename} ......"
        # Do we need to delete '.meta'?
        local elem=$(yq -o yaml ".backupLocations[${idx}]" ${DPDIR}/${filename} | yq -o yaml 'del(.status)')
        if [[ "${elem}" == "null" ]]; then
            break
        fi
        # Just import cluster specific backup/schedule
        fullname=$(echo "${elem}" | yq '.fullName | .managementClusterName + "." + .provisionerName + "." + .clusterName')
        if ! grep -qx "${fullname}" "$ONBOARDED_CLUSTER_INDEX_FILE"; then
            echo "Cluster ${fullname} doesn't exist, just skip it"
            continue
        fi
        # Save kubeconfig
        clname=$(echo "${elem}" | yq '.fullName.clusterName')
        mcname=$(echo "${elem}" | yq '.fullName.managementClusterName')
        provname=$(echo "${elem}" | yq '.fullName.provisionerName')
        if ! get_kubeconfig ${clname} ${provname} ${mcname} ${TEMPKUBECONFIG}; then
            echo "Failed to get kubeconfig for cluster ${mcname}/${provname}/${clname}, skip importing BSL for this cluster"
            continue
        fi
        # Create new BSL
        bslname=$(echo "${elem}" | yq '.fullName.name')
        bslprefix=$(echo "${elem}" | yq '.spec.prefix')
        for ((trynum = 0; trynum < 30; trynum += 1))
        do
            retmsg=$(${KUBECTL} --kubeconfig=${TEMPKUBECONFIG} get bsl -n velero ${bslname} -o yaml)
            newbslname=$(echo "${retmsg}" | yq ".metadata.name")
            if [[ "${newbslname}" == "${bslname}" ]]; then
                echo "${retmsg}" | yq -o yaml 'del(.status)' | yq -o yaml 'del(.metadata.labels)' > ${TEMPFILE}
                # Do we need to append a timestampe to the name? to avoid conflict.
                yq -i ".metadata.name=\"${bslname}-old\"" ${TEMPFILE}
                yq -i ".spec.objectStorage.prefix=\"${bslprefix}\"" ${TEMPFILE}
                cat ${TEMPFILE}
                ${KUBECTL} --kubeconfig=${TEMPKUBECONFIG} apply -f ${TEMPFILE}
                rm -f ${TEMPFILE}
                break
            fi
            echo "try again ${trynum}/30 ..."
            sleep 10
        done
        rm -f ${TEMPKUBECONFIG}
    done
}

# Load backup location for both org and cluster
create_dp_resources "backup_location_org.yaml" "backupLocations" "backup-location" ""
# It seems we don't need create location for cluster, because clusters are in org already.
# And current backup-location create API doesn't support create cluster-backup-location.
#create_dp_resources "backup_location_cluster.yaml" "backupLocations" "backup-location"

# Enable dataprotection on clustergroups and clusters
enable_dataprotection "dataprotection_clustergroups.yaml" "clustergroup"
enable_dataprotection "dataprotection_clusters.yaml" "cluster"

# Load schedule
create_dp_resources "schedule-clustergroup.yaml" "schedules" "schedule" "clustergroup"
create_dp_resources "schedule-cluster.yaml" "schedules" "schedule" "cluster"

# Create old BSL
create_old_bsl "backup_location_cluster.yaml"

rm -f ${TEMPFILE}
rm -f ${TEMPKUBECONFIG}
