#!/bin/bash

set +e

DPDIR=data/data-protection
rm -fr ${DPDIR}
mkdir -p ${DPDIR}

# Save backup location for both org and clsuter
echo "Saving backup-location ......"
tanzu tmc data-protection backup-location list -o yaml -s org > ${DPDIR}/backup_location_org.yaml
tanzu tmc data-protection backup-location list -o yaml -s cluster > ${DPDIR}/backup_location_cluster.yaml

# Save schedule
echo "Saving schedule for clusters ......"
tanzu tmc data-protection schedule list -s cluster -o yaml > ${DPDIR}/schedule-cluster.yaml
echo "Saving schedule for clustergroups ......"
yq -r '.backupLocations[] | .spec.assignedGroups[] | select(.clustergroup) | .clustergroup.name' ${DPDIR}/backup_location_org.yaml | while read -r groupname; do
    echo "    clustergroup: ${groupname}"
    schd=$(tanzu tmc data-protection schedule list -s clustergroup --cluster-group-name ${groupname} -o json)
    if [[ "${schd}" != "{}" ]]; then
        schds=$(echo ${schd} | yq -o yaml -P '.schedules')
        if [[ "${schds}" != "null" ]] && [[ "${schds}" != "[]" ]]; then
            echo "${schds}" >> ${DPDIR}/schedule-clustergroup.yaml
        fi
    fi
done

# Save backup
echo "Saving backup ......"
tanzu tmc data-protection backup list -o yaml > ${DPDIR}/backup.yaml

# Save restore
echo "Saving restore ......"
tanzu tmc data-protection restore list -o yaml > ${DPDIR}/restore.yaml

# The others, these commands support only get/list
echo "Saving others ......"
tanzu tmc data-protection snapshot-location list -o yaml > ${DPDIR}/snapshot_location.yaml
tanzu tmc data-protection template list | while read -r line; do
    templ="${line%% *}"
    if [[ "${templ}" != "NAME" ]]; then
        tanzu tmc data-protection template get ${templ} > ${DPDIR}/template_${templ}.yaml
    fi
done

# dataprotection on clusters/clustergroups
#TMC_ACCESS_TOKEN=<required>
#TMC_SAAS_ENDPOINT=<required>

# For test only
#TMC_ACCESS_TOKEN=$(curl -s -X POST -H "Content-Type=application/x-www-form-urlencoded" https://console-stg.tanzu.broadcom.com/csp/gateway/am/api/auth/api-tokens/authorize --data-urlencode "refresh_token=$MY_CSP_TOKEN" | jq -r '.access_token')
#TMC_SAAS_ENDPOINT="https://trh.tmc-dev.tanzu.broadcom.com"

echo "Saving dataprotection for clustergroups ......"
yq -r '.backupLocations[] | .spec.assignedGroups[] | select(.clustergroup) | .clustergroup.name' ${DPDIR}/backup_location_org.yaml | while read -r groupname; do
    echo "    clustergroup: ${groupname}"
    dpgrp=$(curl -k -s --http1.1 \
            -H "Authorization: Bearer $TMC_ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -X GET \
            ${TMC_SAAS_ENDPOINT}/v1alpha1/clustergroups/${groupname}/dataprotection)
    if [[ "${dpgrp}" != "{}" ]]; then
        dps=$(echo ${dpgrp} | yq -o yaml -P '.dataProtections')
        if [[ "${dps}" != "null" ]] && [[ "${dps}" != "[]" ]]; then
           echo "${dps}"  >> ${DPDIR}/dataprotection_clustergroups.yaml
        fi
    fi
done

echo "Saving dataprotection for clusters ......"
#yq -r '.backupLocations[] | .fullName | .managementClusterName + " " + .provisionerName + " " + .clusterName' ${DPDIR}/backup_location_cluster.yaml | while read -r mgmtname provname clname; do
yq -r '.backupLocations[] | .spec.assignedGroups[] | select(.cluster) | .cluster.managementClusterName + " " + .cluster.provisionerName + " " + .cluster.name' ${DPDIR}/backup_location_org.yaml | while read -r mgmtname provname clname; do
    echo "    cluster: ${clname}"
    dpcl=$(curl -k -s --http1.1 \
            -H "Authorization: Bearer $TMC_ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -X GET \
            ${TMC_SAAS_ENDPOINT}/v1alpha1/clusters/${clname}/dataprotection\?fullName.managementClusterName=${mgmtname}\&fullName.provisionerName=${provname})
    if [[ "${dpcl}" != "{}" ]]; then
        echo ${dpcl} | yq -o yaml -P '.dataProtections' >> ${DPDIR}/dataprotection_clusters.yaml
    fi
done
