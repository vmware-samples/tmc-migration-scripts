# tmc-saas-migration-scripts

This is a repo to store the scripts in the [Migrate TMC SaaS to SM](https://docs.google.com/document/d/1js_kX4ogXArU55jZ6pcjra09gE9L-l4TMuxjzLy0HEg/edit?usp=sharing) doc, which guides how to migrate resources from TMC SaaS to  Self-Managed.

## Script Index

| Script                                                                                                           | Description                                                  | Status | Notes                                                                                                                                                      |
| ---------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------ | ------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [001-base-saas\_stack-connect.sh](./001-base-saas_stack-connect.sh)                                              | Authenticate and connect to the SaaS platform                | READY  | - Include both CLI and API options  - Once the token or context expired, rerun the script to regenerate one                                                |
| [002-base-clustergroups-export.sh](./002-base-clustergroups-export.sh)                                           |                                                              |        |                                                                                                                                                            |
| [003-base-workspaces-export.sh](./003-base-workspaces-export.sh)                                                 |                                                              |        |                                                                                                                                                            |
| [004-admin-roles-export.sh](./004-admin-roles-export.sh)                                                         |                                                              |        |                                                                                                                                                            |
| [005-admin-credentials-export.sh](./005-admin-credentials-export.sh)                                             |                                                              |        |                                                                                                                                                            |
| [006-admin-access-export.sh](./006-admin-access-export.sh)                                                       |                                                              |        |                                                                                                                                                            |
| [007-admin-proxy-export.sh](./007-admin-proxy-export.sh)                                                         |                                                              |        |                                                                                                                                                            |
| [008-admin-image-registry-export.sh](./008-admin-image-registry-export.sh)                                       |                                                              |        |                                                                                                                                                            |
| [009-admin-settings-export.sh](./009-admin-settings-export.sh)                                                   |                                                              |        |                                                                                                                                                            |
| [010-clustergroup-secrets-export.sh](./010-clustergroup-secrets-export.sh)                                       | Export k8s secret resources of cluster groups                | READY  |                                                                                                                                                            |
| [011-clustergroup-secret-exports-export.sh](./011-clustergroup-secret-exports-export.sh)                         | Export k8s secret export resources of cluster groups         | READY  |                                                                                                                                                            |
| [012-clustergroup-continuous-deliveries-export.sh](./012-clustergroup-continuous-deliveries-export.sh)           | Export  fluxcd resources of cluster groups                   | READY  |                                                                                                                                                            |
| [013-clustergroup-repository-credentials-export.sh](./013-clustergroup-repository-credentials-export.sh)         | Export git repo credential resources of cluster groups       | READY  | SaaS API call required                                                                                                                                     |
| [014-clustergroup-git-repositories-export.sh](./014-clustergroup-git-repositories-export.sh)                     | Export git repository resources of cluster groups            | READY  |                                                                                                                                                            |
| [015-clustergroup-kustomizations-export.sh](./015-clustergroup-kustomizations-export.sh)                         | Export kustomization resources of cluster groups             | READY  |                                                                                                                                                            |
| [016-clustergroup-helms-export.sh](./016-clustergroup-helms-export.sh)                                           | Export helm resources of cluster groups                      | READY  |                                                                                                                                                            |
| [017-clustergroup-helm-releases-export.sh](./017-clustergroup-helm-releases-export.sh)                           | Export helm release resources of cluster groups              | READY  |                                                                                                                                                            |
| [018-cluster-namespaces-export.sh](./018-cluster-namespaces-export.sh)                                           | Export managed namespace resources of clusters               | READY  |                                                                                                                                                            |
| [019-cluster-secrets-export.sh](./019-cluster-secrets-export.sh)                                                 | Export k8s secret resources of clusters                      | READY  |                                                                                                                                                            |
| [020-cluster-secret-exports-export.sh](./020-cluster-secret-exports-export.sh)                                   | Export k8s secret export resources of clusters               | READY  |                                                                                                                                                            |
| [021-cluster-continuous-deliveries-export.sh](./021-cluster-continuous-deliveries-export.sh)                     | Export  fluxcd resources of clusters                         | READY  |                                                                                                                                                            |
| [022-cluster-repository-credentials-export.sh](./022-cluster-repository-credentials-export.sh)                   | Export git repo credential resources of clusters             | READY  |                                                                                                                                                            |
| [023-cluster-git-repositories-export.sh](./023-cluster-git-repositories-export.sh)                               | Export git repository resources of clusters                  | READY  |                                                                                                                                                            |
| [024-cluster-kustomizations-export.sh](./024-cluster-kustomizations-export.sh)                                   | Export kustomization resources of clusters                   | READY  |                                                                                                                                                            |
| [025-cluster-helms-export.sh](./025-cluster-helms-export.sh)                                                     | Export helm resources of clusters                            | READY  |                                                                                                                                                            |
| [026-cluster-helm-releases-export.sh](./026-cluster-helm-releases-export.sh)                                     | Export helm release resources of clusters                    | READY  |                                                                                                                                                            |
| [027-cluster-data\_protection-export.sh](./027-cluster-data_protection-export.sh)                                |                                                              |        |                                                                                                                                                            |
| [028-base-access-policies-export.sh](./028-base-access-policies-export.sh)                                       |                                                              |        |                                                                                                                                                            |
| [029-base-policy-templates-export.sh](./029-base-policy-templates-export.sh)                                     |                                                              |        |                                                                                                                                                            |
| [030-base-policy-assignments-export.sh](./030-base-policy-assignments-export.sh)                                 |                                                              |        |                                                                                                                                                            |
| [031-base-managed\_clusters-offboard.sh](./031-base-managed_clusters-offboard.sh)                                | Offboard the managed TKG clusters from TMC SaaS              | READY  | VKS (aka. TKGs) and TKGm clusters                                                                                                                          |
| [032-base-attached\_non\_npc\_clusters-offboard.sh](./032-base-attached_non_npc_clusters-offboard.sh)            | Offboard the attached non-NPC clusters from TMC SaaS         | READY  | Attached Non-NPC clusters                                                                                                                                  |
| [033-base-sm\_stack-connect.sh](./033-base-sm_stack-connect.sh)                                                  |                                                              |        |                                                                                                                                                            |
| [034-base-clustergroups-import.sh](./034-base-clustergroups-import.sh)                                           |                                                              |        |                                                                                                                                                            |
| [035-base-workspaces-import.sh](./035-base-workspaces-import.sh)                                                 |                                                              |        |                                                                                                                                                            |
| [036-admin-roles-import.sh](./036-admin-roles-import.sh)                                                         |                                                              |        |                                                                                                                                                            |
| [037-admin-credentials-create-template.sh](./037-admin-credentials-create-template.sh)                           |                                                              |        |                                                                                                                                                            |
| [037-admin-credentials-import.sh](./037-admin-credentials-import.sh)                                             |                                                              |        |                                                                                                                                                            |
| [038-admin-proxy-create-template.sh](./038-admin-proxy-create-template.sh)                                       |                                                              |        |                                                                                                                                                            |
| [038-admin-proxy-import.sh](./038-admin-proxy-import.sh)                                                         |                                                              |        |                                                                                                                                                            |
| [039-admin-image-registry-create-docker-config-json.sh](./039-admin-image-registry-create-docker-config-json.sh) |                                                              |        |                                                                                                                                                            |
| [039-admin-image-registry-create-template.sh](./039-admin-image-registry-create-template.sh)                     |                                                              |        |                                                                                                                                                            |
| [039-admin-image-registry-import.sh](./039-admin-image-registry-import.sh)                                       |                                                              |        |                                                                                                                                                            |
| [040-clustergroup-secrets-import.sh](./040-clustergroup-secrets-import.sh)                                       | Import k8s secret resources to cluster groups                | READY  |                                                                                                                                                            |
| [041-clustergroup-secret-exports-import.sh](./041-clustergroup-secret-exports-import.sh)                         | Import k8s secret export resources to cluster groups         | READY  |                                                                                                                                                            |
| [042-clustergroup-continuous-deliveries-import.sh](./042-clustergroup-continuous-deliveries-import.sh)           | Import fluxcd resources to cluster groups                    | READY  |                                                                                                                                                            |
| [043-clustergroup-repository-credentials-import.sh](./043-clustergroup-repository-credentials-import.sh)         | Import git repository credential resources to cluster groups | READY  |                                                                                                                                                            |
| [044-clustergroup-git-repositories-import.sh](./044-clustergroup-git-repositories-import.sh)                     | Import git repository resources to cluster groups            | READY  |                                                                                                                                                            |
| [045-clustergroup-kustomizations-import.sh](./045-clustergroup-kustomizations-import.sh)                         | Import kustomization resources to cluster groups             | READY  |                                                                                                                                                            |
| [046-clustergroup-helms-import.sh](./046-clustergroup-helms-import.sh)                                           | Import helm resources to cluster groups                      | READY  |                                                                                                                                                            |
| [047-clustergroup-helm-releases-import.sh](./047-clustergroup-helm-releases-import.sh)                           | Import helm release resources to cluster groups              | READY  |                                                                                                                                                            |
| [048-base-managed\_clusters-onboard.sh](./048-base-managed_clusters-onboard.sh)                                  | Onboard the managed TKG clusters to TMC SM                   | tbd    | - VKS (aka. TKGs) and TKGm clusters  - Prepare the required MC Kubeconfig index file with [048-prepare-for-user-input.sh](./048-prepare-for-user-input.sh) |
| [049-base-non\_npc\_clusters-onboard.sh](./049-base-non_npc_clusters-onboard.sh)                                 | Onboard the attached non-NPC clusters to TMC SM              | tbd    | Attached Non-NPC clusters  - Prepare the required WC Kubeconfig index file with [049-prepare-for-user-input.sh](./049-prepare-for-user-input.sh)           |
| [050-cluster-namespaces-import.sh](./050-cluster-namespaces-import.sh)                                           | Import managed namespace resources to clusters               | READY  |                                                                                                                                                            |
| [051-cluster-secrets-import.sh](./051-cluster-secrets-import.sh)                                                 | Import k8s secret resources to clusters                      | READY  |                                                                                                                                                            |
| [052-cluster-secret-exports-import.sh](./052-cluster-secret-exports-import.sh)                                   | Import k8s secret export resources to clusters               | READY  |                                                                                                                                                            |
| [053-cluster-continuous-deliveries-import.sh](./053-cluster-continuous-deliveries-import.sh)                     | Import fluxcd resources to clusters                          | READY  |                                                                                                                                                            |
| [054-cluster-repository-credentials-import.sh](./054-cluster-repository-credentials-import.sh)                   | Import git repository credential resources to clusters       | READY  |                                                                                                                                                            |
| [055-cluster-git-repositories-import.sh](./055-cluster-git-repositories-import.sh)                               | Import git repository resources to clusters                  | READY  |                                                                                                                                                            |
| [056-cluster-kustomizations-import.sh](./056-cluster-kustomizations-import.sh)                                   | Import kustomization resources to clusters                   | READY  |                                                                                                                                                            |
| [057-cluster-helms-import.sh](./057-cluster-helms-import.sh)                                                     | Import helm resources to clusters                            | READY  |                                                                                                                                                            |
| [058-cluster-helm-releases-import.sh](./058-cluster-helm-releases-import.sh)                                     | Import helm releases resources to clusters                   | READY  |                                                                                                                                                            |
| [059-admin-settings-import.sh](./059-admin-settings-import.sh)                                                   |                                                              |        |                                                                                                                                                            |
| [060-admin-access-import.sh](./060-admin-access-import.sh)                                                       |                                                              |        |                                                                                                                                                            |
| [061-base-access-policies-import.sh](./061-base-access-policies-import.sh)                                       |                                                              |        |                                                                                                                                                            |
| [061-cluster-access-policies-import.sh](./061-cluster-access-policies-import.sh)                                 |                                                              |        |                                                                                                                                                            |
| [062-base-policy-templates-import.sh](./062-base-policy-templates-import.sh)                                     |                                                              |        |                                                                                                                                                            |
| [063-base-policy-assignments-import.sh](./063-base-policy-assignments-import.sh)                                 |                                                              |        |                                                                                                                                                            |
| [063-cluster-policy-assignments-import.sh](./063-cluster-policy-assignments-import.sh)                           |                                                              |        |                                                                                                                                                            |
| [064-cluster-data\_protection-import.sh](./064-cluster-data_protection-import.sh)                                |                                                              |        |                                                                                                                                                            |

**Note:**
Script file name follows pattern `<index>-<scope>-<resource>-<operation>.sh`.
The scope includes:

*   Base

*   Administration

*   Cluster group

*   cluster

Operation includes:

*   Connect: script used to authenticate and connect to the TMC stack (SaaS or SM)

*   Export: script used to export the resources from SaaS

*   Import: script used to import the exported resource to SM

*   Offboard: unmanage the workload cluster and deregister management cluster from SaaS

*   Onboard: register the management cluster to SM and manage the workload clusters

## Run the Scripts

1.  Export the necessary environment variables to set up connection context of SaaS.

    ```shell
    export TANZU_API_TOKEN=<CSP-TOKEN>
    export ORG_NAME=<YOUR-ORG-IDENTITY>
    ```

    Run script [001-base-saas\_stack-connect.sh](./001-base-saas_stack-connect.sh) to create a context for connecting the SaaS stack.

2.  Export the related resources from the SaaS stack by running scripts **002 - 030**.

3.  Offboard the managed clusters from the SaaS stack by running script [031-base-managed\_clusters-offboard.sh](./031-base-managed_clusters-offboard.sh). Set
    the environment variable `TMC_MC_FILTER` to export the specified clusters only.

    ```shell
    # Define the management cluster filter. e.g. "my_mc_1, my_mc_2".
    export TMC_MC_FILTER="my_mc_1, my_mc_2"
    ```

4.  Offboard the attached non-NPC clusters from the SaaS stack by running script [032-base-attached\_non\_npc\_clusters-offboard.sh](./032-base-attached_non_npc_clusters-offboard). Set the environment variable `CLUSTER_NAME_FILTER` to export the specified attached clusters only.

    ```shell
    export CLUSTER_NAME_FILTER="attached1, attached2"
    ```

5.  Export the necessary environment variables to set up connection context of SM.

    ```shell
    export TMC_SELF_MANAGED_USERNAME=admin-user@customer.com
    export TMC_SELF_MANAGED_PASSWORD=Fake@Pass
    export TMC_SELF_MANAGED_DNS=tmc.tanzu.io
    export TMC_SM_CONTEXT=tmc-sm
    ```

    Run script [033-base-sm\_stack-connect.sh](./033-base-sm_stack-connect.sh) to create context for connecting the SM stack.

6.  Import resources `[cluster group, workspace, roles]` into SM by running scripts **034-036**.

7.  \[👤 **USER ACTION REQUIRED**] List user actions needed for running scripts **037-039**.

8.  \[👤 **USER ACTION REQUIRED**] List user action needed for running script **040**.

9.  Import resources `[secrets-exports, CD]` into SM by running scripts **041-042**.

10. \[👤 **USER ACTION REQUIRED**] List user action needed for running script **043**.

11. Imports resources `[clustergroup:git repo, clustergroup:kustomization, clustergroup:helm, clustergroup:helm-release]` by running scripts **044-047**.

12. Run script [048-prepare-for-user-input.sh](./048-prepare-for-user-input.sh) to generate a Kubeconfig index file for the onboarding management clusters. Replace the path placeholders `/path/to/the/real/mc_kubeconfig/file` in the generated Kubeconfig index file.
    Then run script [048-base-managed\_clusters-onboard.sh](./048-base-managed_clusters-onboard.sh) to onboard the exported clusters onto SM.

13. Run script [049-prepare-for-user-input.sh](./049-prepare-for-user-input.sh) to generate a Kubeconfig index file for the attached clusters. Replace the path placeholders `/path/to/the/real/wc_kubeconfig/file` in the generated Kubeconfig index file.

    Then run script [049-base-non\_npc\_clusters-onboard.sh](./049-base-non_npc_clusters-onboard.sh) to onboard the attached clusters onto SM.

14. Import resource `[namespace]` into SM by running script **050**.

15. \[👤 **USER ACTION REQUIRED**] List user actions for **051**.

16. Import resources `[cluster:secret export, cluster:CD]` into SM by running scripts **052-053**

17. \[👤 **USER ACTION REQUIRED**] List user actions for 054.

18. Import resources `[cluster:git, cluster:kustomization, cluster:helm, cluster:helm-release, admin:settings, admin:access]` into SM by running scripts **055-060**

19. Import resources `[access policies, policy templates, policy assignments]` into SM by running scripts **061-063**. **Notes**: TBD for access policy post-import action.

20. Import resources `[Data protection]` 064. **Notes**: TBD to clarify the credentials depends on by DP should be imported in the previous steps.

