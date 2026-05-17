# Contributing

## Development Prerequisites

| Tool | Version | Purpose |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/install) | >= 1.6.0 | Core runtime |
| [tflint](https://github.com/terraform-linters/tflint) | >= 0.50 | Linting with azurerm + google plugins |
| [tfsec](https://github.com/aquasecurity/tfsec) or [trivy](https://github.com/aquasecurity/trivy) | latest | Static security analysis |
| [terraform-docs](https://terraform-docs.io/) | >= 0.16 | README input/output table generation |
| [pre-commit](https://pre-commit.com/) | >= 3.x | Hook runner |

## Local Setup

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files  # verify baseline passes
```

## Running Checks Manually

```bash
# Format check (run from repo root)
terraform fmt -recursive -check

# Lint (requires tflint azurerm + google plugins; see .tflint.hcl)
tflint --recursive

# Security scan
tfsec ./modules
# or: trivy config ./modules

# Regenerate README input/output tables after changing variables.tf / outputs.tf
terraform-docs markdown table --output-file README.md --output-mode inject ./modules/azure/aks-cluster
```

## Test Infrastructure Requirements

`terraform test` runs against real providers — it creates and destroys actual cloud resources.
Do not run tests against shared or production environments.

### Azure

- A dedicated Azure subscription (or a resource group with sufficient permissions).
- Service principal with: `Contributor` on the resource group, `User Access Administrator`
  scoped to the resource group (required to create role assignments in tests).
- Environment variables: `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_SUBSCRIPTION_ID`, `ARM_TENANT_ID`.

### GCP

- A dedicated GCP project.
- Service account with: `roles/editor` or a custom role covering Compute, Container, IAM, and
  Secret Manager.
- Authentication via Application Default Credentials (`gcloud auth application-default login`) or
  `GOOGLE_APPLICATION_CREDENTIALS` pointing to a SA key file.

**TODO:** Replace SA key file auth with OIDC federated credentials for GitHub Actions CI.
See root README testing section for rationale.

## Module Conventions

**Variables**
- Every variable has a `description`.
- Required variables have no `default`.
- Optional variables have the safest reasonable default (e.g., `private_cluster_enabled = false`
  lets the module work in dev without a private DNS zone).
- Enum-like variables have a `validation` block — `environment` must be one of `dev`, `staging`,
  `prod`; it should not silently accept `development` and produce wrong names downstream.

**Outputs**
- Every output has a `description`.
- Export everything a downstream module is likely to need. Adding a missing output later is a
  PATCH bump; removing one is a MAJOR bump. Over-exporting is cheaper than under-exporting.

**General**
- No hardcoded region names, subscription IDs, project IDs, or account numbers inside modules.
- No `count` on resource blocks that would make state address unstable across plan runs — prefer
  `for_each` with a stable map key.
- Resource `tags` (Azure) and `labels` (GCP) are passed through from a variable, not hardcoded
  inside the module. Callers control tagging strategy.

## Versioning

Follow the semver table in the root README. After merging a change to `main`:

1. Identify the highest version bump in the merged PR (PATCH / MINOR / MAJOR).
2. Create and push a new tag: `git tag v1.2.3 && git push origin v1.2.3`.
3. Update the version in `versions.tf` of any module that changed (the module's own version
   constant in `locals`, if present).

Do not amend or delete published tags — consumers may have pinned to them.
