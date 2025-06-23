# tmc-saas-migration-scripts

This is a repo to store the scripts in the [Migrate TMC SaaS to SM](https://docs.google.com/document/d/1js_kX4ogXArU55jZ6pcjra09gE9L-l4TMuxjzLy0HEg/edit?usp=sharing) doc, which guides how to migrate resources from TMC SaaS to  Self-Managed.

## Script Index

| Script | Description | Status | Notes |
|--------|-------------|--------|-------|
| [001-base-saas_stack-connect.sh](./001-base-saas_stack-connect.sh)   | Authenticate and connect to the SaaS platform | tbd | - Include both CLI and API options <br> - Once the token or context expired, rerun the script to regenerate one |
| [031-base-managed_clusters-offboard.sh](./031-base-managed_clusters-offboard.sh) | Offboard the managed TKG clusters from TMC SaaS | tbd | VKS (aka. TKGs) and TKGm clusters |
| [032-base-attached_non_npc_clusters-offboard.sh](./032-base-attached_non_npc_clusters-offboard.sh) | Offboard the attached non-NPC clusters from TMC SaaS | tbd | Attached Non-NPC clusters |
| [048-base-managed_clusters-onboard.sh](./048-base-managed_clusters-onboard.sh) | Onboard the managed TKG clusters to TMC SM | tbd | VKS (aka. TKGs) and TKGm clusters |
| [049-base-non_npc_clusters-onboard.sh](./049-base-non_npc_clusters-onboard.sh) | Onboard the attached non-NPC clusters to TMC SM | tbd | Attached Non-NPC clusters |

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

TBD
