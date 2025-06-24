# tmc-saas-migration-scripts

This is a repo to store the scripts in the [Migrate TMC SaaS to SM](https://docs.google.com/document/d/1js_kX4ogXArU55jZ6pcjra09gE9L-l4TMuxjzLy0HEg/edit?usp=sharing) doc, which guides how to migrate resources from TMC SaaS to  Self-Managed.

## Script Index

| Script | Description | Status | Notes |
|--------|-------------|--------|-------|
| [001-base-saas_stack-connect.sh](./001-base-saas_stack-connect.sh)   | Authenticate and connect to the SaaS platform | READY | - Include both CLI and API options <br> - Once the token or context expired, rerun the script to regenerate one |
| [031-base-managed_clusters-offboard.sh](./031-base-managed_clusters-offboard.sh) | Offboard the managed TKG clusters from TMC SaaS | READY | VKS (aka. TKGs) and TKGm clusters |
| [032-base-attached_non_npc_clusters-offboard.sh](./032-base-attached_non_npc_clusters-offboard.sh) | Offboard the attached non-NPC clusters from TMC SaaS | READY | Attached Non-NPC clusters |
| [048-base-managed_clusters-onboard.sh](./048-base-managed_clusters-onboard.sh) | Onboard the managed TKG clusters to TMC SM | tbd | - VKS (aka. TKGs) and TKGm clusters <br> - Prepare the required MC Kubeconfig index file with [048-prepare-for-user-input.sh](./048-prepare-for-user-input.sh) |
| [049-base-non_npc_clusters-onboard.sh](./049-base-non_npc_clusters-onboard.sh) | Onboard the attached non-NPC clusters to TMC SM | tbd | Attached Non-NPC clusters <br> - Prepare the required WC Kubeconfig index file with [049-prepare-for-user-input.sh](./049-prepare-for-user-input.sh)|

**Note:**
Script file name follows pattern `<index>-<scope>-<resource>-<operation>.sh`.
The scope includes:

- Base
- Administration
- Cluster group
- cluster

Operation includes:

- Connect: script used to authenticate and connect to the TMC stack (SaaS or SM)
- Export: script used to export the resources from SaaS
- Import: script used to import the exported resource to SM
- Offboard: unmanage the workload cluster and deregister management cluster from SaaS
- Onboard: register the management cluster to SM and manage the workload clusters

## Run the Scripts

1. Export the necessary environment variables to set up connection context of SaaS.

    ```shell
    export TANZU_API_TOKEN=<CSP-TOKEN>
    export ORG_NAME=<YOUR-ORG-IDENTITY>
    ```

    Run script [001-base-saas_stack-connect.sh](./001-base-saas_stack-connect.sh) to create a context for connecting the SaaS stack.

1. Export the related resources from the SaaS stack by running scripts **002 - 030**.

1. Offboard the managed clusters from the SaaS stack by running script [031-base-managed_clusters-offboard.sh](./031-base-managed_clusters-offboard.sh). Set
the environment variable `TMC_MC_FILTER` to export the specified clusters only.

    ```shell
    # Define the management cluster filter. e.g. "my_mc_1, my_mc_2".
    export TMC_MC_FILTER="my_mc_1, my_mc_2"
    ```

1. Offboard the attached non-NPC clusters from the SaaS stack by running script [032-base-attached_non_npc_clusters-offboard.sh](./032-base-attached_non_npc_clusters-offboard). Set the environment variable `CLUSTER_NAME_FILTER` to export the specified attached clusters only.

    ```shell
    export CLUSTER_NAME_FILTER="attached1, attached2"
    ```

1. Export the necessary environment variables to set up connection context of SM.

    ```shell
    export TMC_SELF_MANAGED_USERNAME=admin-user@customer.com
    export TMC_SELF_MANAGED_PASSWORD=Fake@Pass
    export TMC_SELF_MANAGED_DNS=tmc.tanzu.io
    export TMC_SM_CONTEXT=tmc-sm
    ```

    Run script [033-base-sm_stack-connect.sh](./033-base-sm_stack-connect.sh) to create context for connecting the SM stack.

1. Import resources `[cluster group, workspace, roles]` into SM by running scripts **034-036**.

1. [👤 **USER ACTION REQUIRED**] List user actions needed for running scripts **037-039**.

1. [👤 **USER ACTION REQUIRED**] List user action needed for running script **040**.

1. Import resources `[secrets-exports, CD]` into SM by running scripts **041-042**.

1. [👤 **USER ACTION REQUIRED**] List user action needed for running script **043**.

1. Imports resources `[clustergroup:git repo, clustergroup:kustomization, clustergroup:helm, clustergroup:helm-release]` by running scripts **044-047**.

1. Run script [048-prepare-for-user-input.sh](./048-prepare-for-user-input.sh) to generate a Kubeconfig index file for the onboarding management clusters. Replace the path placeholders `/path/to/the/real/mc_kubeconfig/file` in the generated Kubeconfig index file.
    Then run script [048-base-managed_clusters-onboard.sh](./048-base-managed_clusters-onboard.sh) to onboard the exported clusters onto SM.

1. Run script [049-prepare-for-user-input.sh](./049-prepare-for-user-input.sh) to generate a Kubeconfig index file for the attached clusters. Replace the path placeholders `/path/to/the/real/wc_kubeconfig/file` in the generated Kubeconfig index file.

    Then run script [049-base-non_npc_clusters-onboard.sh](./049-base-non_npc_clusters-onboard.sh) to onboard the attached clusters onto SM.

1. Import resource `[namespace]` into SM by running script **050**.

1. [👤 **USER ACTION REQUIRED**] List user actions for **051**.

1. Import resources `[cluster:secret export, cluster:CD]` into SM by running scripts **052-053**

1. [👤 **USER ACTION REQUIRED**] List user actions for 054.

1. Import resources `[cluster:git, cluster:kustomization, cluster:helm, cluster:helm-release, admin:settings, admin:access]` into SM by running scripts **055-060**

1. Import resources `[access policies, policy templates, policy assignments]` into SM by running scripts **061-063**. **Notes**: TBD for access policy post-import action.

1. Import resources `[Data protection]` 064. **Notes**: TBD to clarify the credentials depends on by DP should be imported in the previous steps.
