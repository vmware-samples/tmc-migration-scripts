#!/bin/bash

WC_KUBECONFIG_INDEX_FILE="data/clusters/attached-wc-kubeconfig-index-file"

function get_kubeconfig() {
    local cluster_name=$1
    local provisioner_name=$2
    local management_cluster_name=$3
    local kubeconfig_file=$4

    local kubeconfig_dir=$(dirname $kubeconfig_file)
    mkdir -p $kubeconfig_dir

    if [[ "${management_cluster_name}" == "attached" ]]; then
        if [[ -n "$WC_KUBECONFIG_INDEX_FILE" && -f "$WC_KUBECONFIG_INDEX_FILE" ]]; then
            wc_kubeconfig=$(grep "^$cluster_name:" "$WC_KUBECONFIG_INDEX_FILE" | awk '{print $2}')
            if [[ -n "$wc_kubeconfig" && -f "$wc_kubeconfig" ]]; then
                cp -f $wc_kubeconfig $kubeconfig_file
                return 0
            fi
        fi
        
        if ! tanzu tmc cluster kubeconfig get ${cluster_name} -m ${management_cluster_name} -p ${provisioner_name} > ${kubeconfig_file}; then
            return 1
        fi
    elif ! tanzu tmc cluster admin-kubeconfig get ${cluster_name} -m ${management_cluster_name} -p ${provisioner_name} > ${kubeconfig_file}; then
        return 1
    fi

    return 0
}