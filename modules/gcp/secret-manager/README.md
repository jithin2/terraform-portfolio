# gcp/secret-manager

## Purpose

Creates GCP Secret Manager secrets with:
- Configurable replication (automatic or user-managed for data residency)
- Optional initial secret version (for bootstrap values — see gotchas)
- Additive IAM bindings per secret (`iam_member`, not `iam_binding`)

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `project_id` | GCP project ID | `string` | — | yes |
| `secrets` | Map of secret configs | `map(object)` | — | yes |
| `iam_bindings` | List of IAM member bindings | `list(object)` | `[]` | no |
| `labels` | Labels applied to all secrets | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| `secret_ids` | Map of key → full secret resource ID |
| `secret_names` | Map of key → secret_id (short name) |
| `secret_resource_paths` | Map of key → latest version path |

## Usage

```hcl
module "secrets" {
  source = "../../gcp/secret-manager"

  project_id = var.project_id

  secrets = {
    "db-password" = {
      replication_type = "automatic"
    }
    "api-key" = {
      replication_type = "automatic"
      labels           = { rotation = "manual" }
    }
  }

  iam_bindings = [
    {
      secret_key = "db-password"
      role       = "roles/secretmanager.secretAccessor"
      member     = "serviceAccount:${module.gke.node_service_account_email}"
    }
  ]

  labels = module.naming.labels
}
```

## Gotchas

- **`initial_value` is stored in Terraform state in plaintext.** This is acceptable for
  non-sensitive bootstrap values (e.g., a known default config). For credentials and API
  keys, create the secret resource in Terraform but populate the version value outside
  Terraform (via `gcloud secrets versions add` in CI/CD, or a secrets rotation tool).
- **`iam_member` vs `iam_binding`.** This module uses `google_secret_manager_secret_iam_member`
  (additive). If you also have `google_secret_manager_secret_iam_binding` (authoritative) on
  the same secret managed elsewhere, the authoritative binding will overwrite what this module
  adds. Pick one approach and do not mix them on the same secret.
- **`secret_resource_paths` uses `/versions/latest`.** This always resolves to the newest
  enabled version at runtime. If your application needs to pin to a specific version for
  reproducible deploys, reference `versions/N` explicitly in application config.
- **Replication type cannot be changed after creation.** `automatic` vs `user_managed` is
  set at secret creation time and is immutable. Changing it requires destroying and recreating
  the secret — which also destroys all versions. Plan this before initial deploy.
