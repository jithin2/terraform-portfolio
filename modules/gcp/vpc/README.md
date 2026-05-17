# gcp/vpc

<!-- TODO(Step 3): Expand after module is implemented. -->

## Purpose

Creates a custom-mode GCP VPC with:
- Custom subnet definitions (one per map entry, multi-region supported)
- Per-subnet secondary IP ranges for GKE pods and services
- `private_ip_google_access = true` by default (required for GKE private clusters)
- Optional Cloud NAT for outbound internet access

VPC firewall rules are **not** created in this module — they belong in the consuming
configuration to avoid conflicts with GKE-managed auto-rules.

## Inputs

<!-- TODO: Run `terraform-docs markdown table .` after variables.tf is complete. -->

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_id` | GCP project ID | `string` | — | yes |
| `network_name` | VPC network name | `string` | — | yes |
| `subnets` | Map of subnet configs | `map(object)` | — | yes |
| `routing_mode` | `REGIONAL` or `GLOBAL` | `string` | `"REGIONAL"` | no |
| `create_nat` | Create Cloud NAT | `bool` | `false` | no |
| `nat_router_region` | Region for Cloud Router | `string` | `null` | no |
| `labels` | Resource labels | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| `network_id` | VPC network ID |
| `network_name` | VPC network name |
| `network_self_link` | VPC self_link (pass to GKE) |
| `subnet_ids` | Map of subnet name → ID |
| `subnet_self_links` | Map of subnet name → self_link |
| `subnet_secondary_ranges` | Map of subnet name → secondary range list |

## Usage

```hcl
module "vpc" {
  source = "../../gcp/vpc"

  project_id   = var.project_id
  network_name = module.naming.name

  subnets = {
    "gke-nodes" = {
      ip_cidr_range = "10.0.0.0/22"
      region        = "us-east1"
      secondary_ip_ranges = [
        { range_name = "pods",     ip_cidr_range = "10.1.0.0/16" },
        { range_name = "services", ip_cidr_range = "10.2.0.0/20" }
      ]
    }
  }

  create_nat        = true
  nat_router_region = "us-east1"

  labels = module.naming.labels
}
```

## Gotchas

- **Secondary range names must match GKE module inputs.** If this module creates a range
  named `pods` and the GKE module receives `pods_secondary_range_name = "pod-range"`, the
  cluster creation fails with a confusing "subnet not found" error. Keep names consistent.
- **`private_ip_google_access = true` is not the same as Private Google Access on an
  org policy level.** It enables Private Google Access for the subnet only.
- **Cloud NAT is not needed if Private Google Access covers all your API calls.** GKE nodes
  pulling from Artifact Registry (gcr.io) over Google's internal network do not go through
  NAT. Only traffic destined for the public internet needs NAT.
- **Firewall rules are not created here.** GKE creates its own rules (`gke-CLUSTER-*`).
  If you manage additional rules in Terraform, do not import or name resources that match
  GKE's auto-naming pattern — they will conflict on cluster recreation.
