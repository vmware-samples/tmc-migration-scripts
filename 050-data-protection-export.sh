#!/bin/bash

set -e

DPDIR=data-protection-data
rm -fr ${DPDIR}
mkdir -p ${DPDIR}

# Save backup location for both org and clsuter
echo "Saving backup-location ......"
tanzu tmc data-protection backup-location list -o yaml -s org > ${DPDIR}/backup_location_org.yaml
tanzu tmc data-protection backup-location list -o yaml -s cluster > ${DPDIR}/backup_location_cluster.yaml

# Save schedule
echo "Saving schedule ......"
tanzu tmc data-protection schedule list -o yaml > ${DPDIR}/schedule.yaml

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

echo "Saving dataprotection for clustergroups ......"
yq -r '.backupLocations[] | .spec.assignedGroups[] | select(.clustergroup) | .clustergroup.name' ${DPDIR}/backup_location_org.yaml | while read -r groupname; do
    echo "    clustergroup: ${groupname}"
    dpgrp=$(curl -k -s --http1.1 \
            -H "Authorization: Bearer $TMC_ACCESS_TOKEN" \
            -H "Content-Type: application/json" \
            -X GET \
	    ${TMC_SAAS_ENDPOINT}/v1alpha1/clustergroups/${groupname}/dataprotection)
    if [[ "${dpgrp}" != "{}" ]]; then
        echo ${dpgrp} | yq -o yaml -P '.dataProtections' >> ${DPDIR}/dataprotection_clustergroups.yaml
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
    if [[ "${dpgrp}" != "{}" ]]; then
        echo ${dpcl} | yq -o yaml -P '.dataProtections' >> ${DPDIR}/dataprotection_clusters.yaml
    fi
done
