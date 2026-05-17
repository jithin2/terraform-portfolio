# azure/aks-cluster

## Purpose

Manages an AKS cluster with:
- A dedicated system node pool (critical add-ons only)
- Zero or more user node pools defined as a map (stable `for_each` state addressing)
- Optional private cluster with configurable DNS zone handling
- OIDC issuer + Workload Identity enabled by default
- Azure CNI network profile (predictable IP allocation, direct pod IPs)
- Separation of control-plane identity and kubelet identity

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `resource_group_name` | RG for the cluster | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `cluster_name` | AKS cluster name | `string` | — | yes |
| `default_node_pool` | System node pool config | `object` | — | yes |
| `user_node_pools` | Map of user node pool configs | `map(object)` | `{}` | no |
| `private_cluster_enabled` | Enable private API server | `bool` | `false` | no |
| `private_dns_zone_id` | DNS zone for private cluster | `string` | `null` | no |
| `sku_tier` | Cluster SLA tier | `string` | `"Standard"` | no |
| `kubernetes_version` | K8s version (null = AKS default) | `string` | `null` | no |
| `identity_type` | `SystemAssigned` or `UserAssigned` | `string` | `"SystemAssigned"` | no |
| `kubelet_identity_id` | User-assigned identity for kubelet | `string` | `null` | no |
| `oidc_issuer_enabled` | Enable OIDC issuer | `bool` | `true` | no |
| `workload_identity_enabled` | Enable Workload Identity | `bool` | `true` | no |
| `network_profile` | Network plugin and policy config | `object` | Azure CNI defaults | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| `cluster_id` | AKS resource ID |
| `cluster_name` | Cluster name |
| `cluster_fqdn` | Public API server FQDN |
| `private_fqdn` | Private API server FQDN (private clusters only) |
| `oidc_issuer_url` | OIDC issuer URL (for federated credential setup) |
| `kubelet_identity` | Kubelet managed identity object |
| `cluster_identity` | Control-plane managed identity object |
| `node_resource_group` | MC_ resource group name |
| `kube_config_raw` | Raw kubeconfig (sensitive) |

## Usage

```hcl
module "naming" {
  source              = "../../shared/naming"
  environment         = "prod"
  region_abbreviation = "eus"
  application         = "payments"
  resource_type       = "aks"
}

module "aks" {
  source = "../../azure/aks-cluster"

  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus"
  cluster_name        = module.naming.name

  default_node_pool = {
    name                 = "system"
    vm_size              = "Standard_D4ds_v5"
    min_count            = 2
    max_count            = 4
    vnet_subnet_id       = module.vnet.subnet_ids["aks-system"]
    only_critical_addons = true
  }

  user_node_pools = {
    "apppool" = {
      vm_size        = "Standard_D8ds_v5"
      min_count      = 2
      max_count      = 10
      vnet_subnet_id = module.vnet.subnet_ids["aks-user"]
      node_taints    = ["workload=app:NoSchedule"]
    }
  }

  private_cluster_enabled = true
  private_dns_zone_id     = azurerm_private_dns_zone.aks.id

  tags = module.naming.labels
}
```

## Gotchas

- **Two identities, one cluster.** The control-plane identity manages cluster infrastructure
  (needs Network Contributor on subnet, DNS Contributor on private zone). The kubelet identity
  is used by pods via Workload Identity. Assigning pod-scoped roles to the control-plane identity
  is a common mistake and a security risk.
- **`only_critical_addons = true` on the system pool.** This applies a `CriticalAddonsOnly=true:NoSchedule`
  taint. Every workload pod needs a matching toleration or it will be `Pending`. This is
  intentional — but it surprises teams who forget the toleration.
- **Azure CNI subnet sizing.** Azure CNI pre-allocates IPs: `(max_count × max_pods_per_node)`.
  Default `max_pods = 30`. A 10-node pool at max_count needs at least a `/25` (126 IPs) to
  avoid exhaustion. Subnet too small surfaces as a provisioning timeout, not an IP error.
- **`user_node_pools` taint changes force pool recreation.** `node_taints` is immutable on
  `azurerm_kubernetes_cluster_node_pool`. Plan the initial taint set carefully.
- **`kubernetes_version = null` allows AKS to auto-upgrade the cluster.** This can trigger
  unplanned node pool recreations. Pin the version for production clusters.
