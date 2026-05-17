# shared/naming

## Purpose

Produces deterministic resource names and standard labels from four structured inputs:
`environment`, `region_abbreviation`, `application`, and `resource_type`.

Output pattern: `{env}-{region}-{app}-{type}` → `prod-eus-payments-aks`

All Azure and GCP modules in this repository consume this module, ensuring resources
in equivalent logical positions on both clouds follow the same naming convention.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `environment` | Deployment environment (`dev`, `staging`, `prod`) | `string` | — | yes |
| `region_abbreviation` | Short region code, max 6 chars | `string` | — | yes |
| `application` | Application identifier, lowercase alphanumeric + hyphens | `string` | — | yes |
| `resource_type` | Resource type suffix (`aks`, `vnet`, `kv`, `gke`, `vpc`, `sm`) | `string` | — | yes |
| `separator` | Segment separator character | `string` | `"-"` | no |

## Outputs

| Name | Description |
|---|---|
| `name` | Full name: `env-region-app-type` |
| `prefix` | Name without resource_type suffix |
| `slug` | Name with separators stripped (for storage accounts, GCS buckets) |
| `labels` | Standard label/tag map to apply to all resources |

## Usage

```hcl
module "naming" {
  source = "../../shared/naming"

  environment         = "prod"
  region_abbreviation = "eus"
  application         = "payments"
  resource_type       = "aks"
}

resource "azurerm_kubernetes_cluster" "this" {
  name = module.naming.name    # "prod-eus-payments-aks"
  tags = module.naming.labels
  # ...
}
```

## Gotchas

- **Region abbreviation consistency is the caller's responsibility.** There is no canonical
  short-name list baked into this module. Establish a convention in your consuming repo and
  document it — `eus` = East US, `ue1` = us-east1 — and stick to it.
- **`slug` includes a plan-time length check.** Azure storage accounts are capped at 24 chars.
  If the combined slug exceeds 24 characters, the module raises an error at plan time rather
  than letting an apply fail with a cryptic ARM error.
- **`labels` is not a merge of caller-provided tags.** It contains only the standard keys
  derived from naming inputs. Callers should `merge(module.naming.labels, var.additional_tags)`
  when applying to resources.
