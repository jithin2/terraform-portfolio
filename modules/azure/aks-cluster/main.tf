# TODO(Step 2): Implement AKS cluster resources.
#
# Resources:
#
#   azurerm_kubernetes_cluster "this"
#     · default_node_pool — system pool only; apply CriticalAddonsOnly=true:NoSchedule taint
#       so user workloads don't land here. Requires consumers to add the toleration.
#     · identity — SystemAssigned or user-assigned depending on var.identity_type.
#       NOTE: The control-plane identity is separate from the kubelet identity.
#       Control-plane identity needs Network Contributor on the subnet (Azure CNI)
#       and Private DNS Zone Contributor if private_cluster_enabled + BYO DNS zone.
#     · oidc_issuer_enabled = true, workload_identity_enabled = true
#       These are a pair — enabling one without the other is a no-op for pod auth.
#     · private_cluster_enabled, private_dns_zone_id
#       When private_dns_zone_id = "System", Azure manages the zone in MC_ RG.
#       Pass an actual zone ID for hub/spoke topologies (BYO pattern).
#     · network_profile with network_plugin = "azure" (Azure CNI) preferred for
#       enterprise: predictable IP allocation, no overlay network, direct pod IPs.
#       Requires larger subnets (pre-allocates IPs per node).
#     · azure_active_directory_role_based_access_control — managed AAD integration.
#       azure_rbac_enabled = true lets you use Azure role assignments for K8s RBAC.
#
#   azurerm_kubernetes_cluster_node_pool "user" (for_each over var.user_node_pools)
#     · mode = "User" — never route system add-ons here
#     · enable_auto_scaling, min_count, max_count from pool config
#     · node_taints, node_labels from pool config for workload isolation
#     · os_disk_type = "Ephemeral" preferred for stateless nodes: faster attach,
#       billed as part of VM, no separate managed disk cost.
#       Not all VM SKUs support ephemeral — validate against the SKU.
#
#   azurerm_role_assignment "kubelet_subnet" (conditional on Azure CNI)
#     · Network Contributor on the node subnet, assigned to the kubelet identity.
#     · Scope to the specific subnet, not the whole VNet — least-privilege.
#
# Key design decisions:
#   - for_each on user_node_pools (map keyed by pool name) produces stable state
#     addresses. Using count would shift addresses if a middle pool is removed.
#   - kube_config_raw is output as sensitive — callers store it in Key Vault or
#     Secrets Manager, not in terraform.tfstate on a shared backend.
#   - kubernetes_version is optional; when null, AKS uses the latest recommended.
#     Pinning is recommended for production — AKS can force-upgrade unversioned clusters.
