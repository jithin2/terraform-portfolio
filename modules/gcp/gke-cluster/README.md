# gcp/gke-cluster

## Purpose

Creates a GKE Standard cluster with:
- `remove_default_node_pool = true` pattern (cluster + separate managed node pools)
- Workload Identity enabled (GKE_METADATA mode on all node pools)
- VPC-native networking (alias IP ranges from named secondary ranges)
- Private cluster support (private nodes, optional private master endpoint)
- Configurable release channel
- Dedicated minimal node service account (not the default Compute SA)

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_id` | GCP project ID | `string` | — | yes |
| `location` | Region or zone | `string` | — | yes |
| `cluster_name` | Cluster name | `string` | — | yes |
| `network` | VPC network self_link | `string` | — | yes |
| `subnetwork` | Subnetwork self_link | `string` | — | yes |
| `pods_secondary_range_name` | Subnet secondary range for pods | `string` | — | yes |
| `services_secondary_range_name` | Subnet secondary range for services | `string` | — | yes |
| `master_cidr` | Master /28 CIDR | `string` | — | yes |
| `node_pools` | Map of node pool configs | `map(object)` | — | yes |
| `private_cluster_config` | Private cluster settings | `object` | private nodes, public master | no |
| `master_authorized_networks` | CIDRs for master access | `list(object)` | `[]` | no |
| `release_channel` | `RAPID`, `REGULAR`, `STABLE` | `string` | `"REGULAR"` | no |
| `create_node_sa` | Create dedicated node SA | `bool` | `true` | no |
| `labels` | Resource labels | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| `cluster_id` | Full cluster resource ID |
| `cluster_name` | Cluster name |
| `cluster_endpoint` | Master API server IP (sensitive) |
| `cluster_ca_certificate` | Cluster CA cert (sensitive) |
| `workload_identity_pool` | `PROJECT_ID.svc.id.goog` |
| `node_service_account_email` | Node SA email |
| `location` | Cluster location |

## Usage

```hcl
module "gke" {
  source = "../../gcp/gke-cluster"

  project_id   = var.project_id
  location     = "us-east1"
  cluster_name = module.naming.name

  network    = module.vpc.network_self_link
  subnetwork = module.vpc.subnet_self_links["gke-nodes"]

  pods_secondary_range_name     = "pods"
  services_secondary_range_name = "services"
  master_cidr                   = "172.16.0.0/28"

  private_cluster_config = {
    enable_private_nodes    = true
    enable_private_endpoint = false
  }

  node_pools = {
    "app" = {
      machine_type   = "n2-standard-8"
      min_node_count = 2
      max_node_count = 10
    }
  }

  labels = module.naming.labels
}
```

## Gotchas

- **`remove_default_node_pool = true` is a one-time operation.** It tells GKE to delete the
  bootstrapping default pool after cluster creation. If you toggle it on an existing cluster,
  Terraform will try to recreate the cluster. Do not change this after initial apply.
- **`master_cidr` must be /28.** GKE rejects any other prefix length. This CIDR must not
  overlap with node IPs, pod ranges, service ranges, or any peered VPC range — the error
  message when it does overlap is generic.
- **Workload Identity requires `GKE_METADATA` on node pools.** Without it, pods fall through
  to the node SA credentials, which silently bypasses the Workload Identity binding. You see
  the problem only when you check what identity the pod actually used.
- **`release_channel` and `min_master_version` interact.** If you set a `min_master_version`
  lower than the channel's current minimum, GKE silently ignores it. If you set it higher,
  GKE upgrades immediately. Document your intent clearly.
- **Private Google Access on the subnet.** Nodes in a private cluster need Private Google
  Access enabled on the subnetwork to reach Container Registry, Secret Manager, and other
  Google APIs. Without it, image pulls silently fail.
