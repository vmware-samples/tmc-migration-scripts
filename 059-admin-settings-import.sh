#!/bin/bash
# Resource: Settings (Under Administration)

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
DATA_DIR="$SCRIPT_DIR"/data/setting
scopes=("cluster" "clustergroup" "organization")
setting_json_template='{"type":{"kind":"Setting","version":"v1alpha1","package":"vmware.tanzu.manage.v1alpha1.cluster.setting.Setting"},"fullName":{"name":""},"spec":{}}'

if [ ! -d $DATA_DIR ]; then
  echo "Nothing to do without directory $DATA_DIR, please backup data first"
  exit 0
fi

for scope in "${scopes[@]}"; do
  settingList=$(cat $DATA_DIR/$scope/settings.yaml | yq eval -o=json - | jq -c '.effective[]')
  while IFS= read -r setting; do
    if [[ -z "$setting" ]]; then
      echo "No any $scope level settings"
    fi
    if [[ -n "$setting" ]]; then
      spec=$(echo "$setting" | jq ".spec.settingSpec // {}")
      settingType=$(echo "$setting" | jq -r ".spec.settingType")
      sourceRid=$(echo "$setting" | jq -r '.spec.source.rid // ""')

      oldIFS=$IFS
      IFS=':'
      sourceRidParts=($sourceRid)
      IFS=$oldIFS

      if [[ "$scope" == "cluster" ]]; then
        filename="${sourceRidParts[6]}--${sourceRidParts[5]}--${sourceRidParts[4]}--${sourceRidParts[3]}"
        echo $setting_json_template | \
          jq --argjson spec "$spec" '.spec = $spec' | \
          jq --arg settingType "$settingType" '.fullName.name = $settingType' | \
          jq --argjson managementClusterNameJson "{\"managementClusterName\": \"${sourceRidParts[3]}\"}" '.fullName += $managementClusterNameJson'  | \
          jq --argjson provisionerNameJson "{\"provisionerName\": \"${sourceRidParts[4]}\"}" '.fullName += $provisionerNameJson'  | \
          jq --argjson clusterNameJson "{\"clusterName\": \"${sourceRidParts[5]}\"}" '.fullName += $clusterNameJson'  | \
          yq eval -P -  | tanzu tmc setting create --scope "$scope" --file -

      elif [[ "$scope" == "clustergroup" ]]; then
        filename="${sourceRidParts[4]}--${sourceRidParts[3]}"
        echo $setting_json_template | \
          jq --argjson spec "$spec" '.spec = $spec' | \
          jq --arg settingType "$settingType" '.fullName.name = $settingType' | \
          jq --argjson clusterGroupNameJson "{\"clusterGroupName\": \"${sourceRidParts[3]}\"}" '.fullName += $clusterGroupNameJson'  | \
          yq eval -P -  | tanzu tmc setting create --scope "$scope" --file -

      elif [[ "$scope" == "organization" ]]; then
        filename=${settingType}
        echo $setting_json_template | \
          jq --argjson spec "$spec" '.spec = $spec' | \
          jq --arg settingType "$settingType" '.fullName.name = $settingType' | \
          yq eval -P -  | tanzu tmc setting create --scope "$scope" --file -
      fi
    fi
  done <<< "$settingList"
done
