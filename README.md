# terraform-portfolio

A library of opinionated Terraform modules for **Azure** and **GCP**, built to enterprise patterns.

*Authored by [Jithin Karkera](https://github.com/jithin2)*

> **Provider version notice:** All `versions.tf` files pin to a tested range.
> Verify those ranges against current releases before deploying to any environment:
> [azurerm](https://registry.terraform.io/providers/hashicorp/azurerm/latest) ·
> [google](https://registry.terraform.io/providers/hashicorp/google/latest) ·
> [Terraform releases](https://github.com/hashicorp/terraform/releases)

---

## Contents

- [Design Philosophy](#design-philosophy)
- [Module Catalogue](#module-catalogue)
- [Library vs Template](#library-vs-template)
- [Azure vs GCP: Where It Bites Engineers](#azure-vs-gcp-where-it-bites-engineers)
- [Testing Approach](#testing-approach)
- [Versioning Strategy](#versioning-strategy)
- [Using the Examples](#using-the-examples)
- [Contributing](#contributing)

---

## Design Philosophy

### 1. Composability over convenience

Each module manages a single, well-scoped concern. Modules receive dependency identifiers as
inputs — subnet IDs, managed identity IDs, DNS zone IDs — rather than creating those dependencies
internally. This means you can use the AKS module against a VNet your networking team already
manages, and you can replace any module without touching the others.

The trade-off: callers write more glue code in the `examples/` layer. That cost is worth paying
because it keeps blast radius small, makes the dependency graph explicit in code, and avoids the
class of bug where a convenience wrapper creates a resource the caller didn't know existed.

### 2. Naming consistency across clouds

The `shared/naming` module produces deterministic resource labels from four inputs:
**environment**, **region abbreviation**, **application**, and **resource type**.
Every Azure and GCP module consumes this module, so a resource in the same logical position on
both clouds gets a predictable, comparable name (`prod-eus-payments-aks`, `prod-ue1-payments-gke`).

Why this matters at enterprise scale: when you have 30 environments across two clouds, ad-hoc
naming leads to drift. A single naming module means one place to change the convention, one place
to enforce it in policy, and one line of code to trace when a name looks wrong.

### 3. Least-privilege defaults

Role assignments and IAM bindings are scoped to the minimum required for the declared function.
No module grants Owner, Editor, or equivalent broad permissions by default. Consumers extend
permissions by adding assignments outside the module; modules do not escalate beyond their
stated purpose. This is intentional — it forces explicit decisions at the call site rather than
hiding privilege escalation inside a module that looks innocuous.

---

## Module Catalogue

| Module | Cloud | Purpose |
|---|---|---|
| `modules/azure/aks-cluster` | Azure | AKS cluster with system + user node pools, managed identity, optional private cluster, OIDC issuer |
| `modules/azure/vnet` | Azure | Hub/spoke-ready VNet with subnets and NSGs |
| `modules/azure/key-vault` | Azure | Key Vault with RBAC authorization mode and optional private endpoint |
| `modules/gcp/gke-cluster` | GCP | GKE Standard cluster with Workload Identity, configurable release channel |
| `modules/gcp/vpc` | GCP | VPC with secondary IP ranges for pods and services |
| `modules/gcp/secret-manager` | GCP | Secret Manager secrets with IAM bindings |
| `modules/shared/naming` | Both | Naming convention module producing consistent labels across clouds |

---

## Library vs Template

### Using as a library

Reference a module directly from this repository at a pinned tag:

```hcl
module "aks" {
  source = "git::https://github.com/jithin2/terraform-portfolio.git//modules/azure/aks-cluster?ref=v1.2.0"

  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus"
  cluster_name        = module.naming.resource_name
  # ...
}
```

Upgrade by changing `ref` and running `terraform init`. Your state is unaffected until
`terraform apply` runs.

**Pros:** easy to adopt, upgrades are opt-in and explicit, no fork to maintain.
**Cons:** you depend on this repo's stability; a breaking change in a new tag requires a code
change in your consuming stack.

### Using as a template

Fork the repo, adjust the naming convention and provider version ranges to your org's standards,
then publish to a Terraform Cloud private registry or an internal Gitea/Artifactory instance.
Consuming stacks reference your internal registry instead of GitHub directly.

**Pros:** full control, can publish to a locked-down registry, can add org-specific validation.
**Cons:** you own the maintenance burden; merging upstream improvements is a manual rebase.

---

## Azure vs GCP: Where It Bites Engineers

This section documents differences that appear as real bugs or operational surprises, not just
API-level distinctions that are obvious from the provider docs.

### Identity and Workload Authentication

**Azure Managed Identity on AKS — two identities, one cluster**

AKS clusters have two separate identities that are easy to confuse:

1. **Control-plane identity** — used by the AKS control plane to manage cluster infrastructure on
   your behalf. For a private cluster with Azure-managed DNS, this identity needs
   `Private DNS Zone Contributor` on the private DNS zone. For Azure CNI, it needs
   `Network Contributor` on the subnet. Getting either wrong produces a cryptic ARM provisioning
   error with no clear pointer to the missing RBAC assignment.

2. **Kubelet identity** (a user-assigned managed identity on the node VMSS) — used by workloads
   that opt into AKS Workload Identity. The full chain requires: OIDC issuer enabled on the
   cluster → a federated credential on the user-assigned managed identity referencing the OIDC
   issuer URL and the K8s namespace/service-account → the annotation
   `azure.workload.identity/client-id` on the K8s ServiceAccount. Misconfigure any link in that
   chain and you get a silent 401 at token exchange time, not a clear error from AKS.

**GCP Workload Identity on GKE — one binding, one annotation**

GKE uses a single binding model: a Kubernetes service account is linked to a GCP service account
via an IAM binding (`roles/iam.workloadIdentityUser`) on the GCP SA, plus the annotation
`iam.gke.io/gcp-service-account` on the K8s SA. The IAM member string must be in the form
`serviceAccount:PROJECT_ID.svc.id.goog[K8S_NAMESPACE/K8S_SA]` — the project ID part comes from
the GKE cluster's project, not the project where the GCP SA lives, which trips people up in
shared-VPC and cross-project architectures.

**Practical difference for module consumers:** Azure's federated credential is a discrete ARM
resource you manage in Terraform and that can drift independently of the K8s SA annotation. GCP's
equivalent is an IAM policy binding that can also drift. Both are stateful outside Kubernetes —
handle them explicitly in Terraform rather than in post-deployment scripts.

---

### Network Security Model

**Azure NSGs — stateful, subnet-scoped, priority-ordered**

NSGs are stateful and attached to a subnet or NIC. Rules are evaluated by priority (lower number
= first match wins). Azure adds default rules you cannot delete: allow inbound from
`VirtualNetwork` tag, allow inbound from `AzureLoadBalancer` tag, deny all other inbound.

Where this bites you with AKS:
- **Azure CNI IP exhaustion**: Azure CNI pre-allocates IPs from the subnet at node pool creation
  time. If your subnet is too small for the pre-allocated pool, nodes fail to join. This is not
  a networking error — it surfaces as a provisioning timeout with no clear IP-exhaustion message.
- **Private cluster route tables**: On private AKS, the kubelet communicates with the API server
  via the subnet's route table. If a custom route table sends that traffic to a firewall that
  blocks it, the node registers but shows `NotReady` with no obvious networking error in the AKS
  portal blade.

**GCP VPC Firewall Rules — VPC-level, tag or SA targeted**

GCP firewall rules are applied at the VPC level, not per-subnet. GKE automatically creates rules
named `gke-CLUSTER_NAME-*` for internal cluster traffic (master-to-node, node-to-node, health
checks). These GKE-managed rules are not managed by your Terraform state.

Where this bites you:
- **Terraform destroy on GKE-managed rules**: If you have a Terraform resource that matches a
  GKE-managed rule by name (e.g., you imported it), `terraform destroy` will delete it, but GKE
  will recreate it. This makes destroy/recreate cycles confusing and leaves orphan rules.
- **Auto-rule naming drift**: When you recreate a cluster with the same name but different config,
  GKE may reuse old rule names. Old rules from a previous cluster run may persist if the delete
  did not clean up properly.

---

### Private Cluster Patterns

**AKS Private Cluster — DNS is the hard part**

The API server is a Private Link endpoint injected into your VNet. Three DNS modes:

| Mode | How it works | Enterprise fit |
|---|---|---|
| `System` (default) | Azure creates a `GUID.privatelink.REGION.azmk8s.io` zone in the `MC_` RG and links it to your VNet | Poor — zone is in the managed RG, which org policies often restrict |
| `None` | No DNS management — you manage the A record manually | Acceptable in mature DNS-as-code environments |
| BYO zone (pass zone ID) | You own the private DNS zone; AKS populates the A record | Preferred — links to hub VNet, respects hub/spoke DNS resolver topology |

`kubectl` access from outside the VNet requires a jump host, VPN, or ExpressRoute. This is
commonly discovered during an incident when someone on the team tries to `kubectl exec` from
a laptop.

**GKE Private Cluster — master CIDR conflicts**

The GKE master runs in a Google-managed VPC peered into your VPC. You specify a `/28` for the
master IP range. This CIDR must not overlap with your node range, pod range (`--cluster-secondary-range-name`),
services range (`--services-secondary-range-name`), or any peered VPC. The error when it does
overlap is a generic "IP conflict" that does not identify which range is the problem.

Private Google Access must be enabled on the node subnet for nodes to reach Google APIs and
Container Registry. Without it, image pulls fail silently until you check the node's serial
console log.

---

### AKS vs GKE Node Pool Taint Behaviour

Both support Kubernetes node taints configured in Terraform, but taint changes have different
operational consequences:

**AKS**: `node_taints` on `azurerm_kubernetes_cluster_node_pool` is an immutable field — any
change forces destroy-and-recreate of the node pool. In production this means draining workloads
manually or accepting disruption. The system node pool's default taint
(`CriticalAddonsOnly=true:NoSchedule`) is often added by teams to keep it clean, but every
workload pod then needs a matching toleration — a detail that bites teams at 3am when they wonder
why a pod is `Pending`.

**GKE**: `node_config.taint` on `google_container_node_pool` triggers a rolling node replacement
(blue/green or surge, depending on your upgrade strategy). Less disruptive than AKS, but you
still need spare capacity for the surge.

---

### Secret and Key Management Integration

**Azure Key Vault — data plane vs management plane, and the firewall**

Key Vault has two distinct access layers:

- **Management plane** (`Microsoft.KeyVault/vaults/*`) — governed by Azure RBAC (standard role
  assignments). `Key Vault Contributor` covers this plane.
- **Data plane** (reading/writing secrets, keys, certs) — governed by either vault access
  policies (legacy) or Azure RBAC (current). This module uses RBAC mode. `Key Vault Secrets User`
  covers read-only data plane access; `Key Vault Secrets Officer` covers create/update.

The two planes are independent. A service principal can have `Key Vault Contributor` (management)
but zero data plane access, and vice versa. This surprises engineers who expect Contributor to
"just work."

Key Vault's network firewall (`network_acls`) is separate from its RBAC. In a private-endpoint
configuration, the vault is accessible only via the private endpoint IP — the firewall must be
set to `Deny` for public traffic. The AKS node subnet either needs an allow rule in the firewall
**or** a private endpoint on that subnet (the two approaches are mutually exclusive and tutorials
mix them up constantly).

**GCP Secret Manager — IAM-only, version-aware**

Secret Manager has no network firewall equivalent. Access is purely IAM. `roles/secretmanager.secretAccessor`
on a specific secret grants access to all versions of that secret. If you need to lock a workload
to a specific version, you do it in the application code by using the full resource name
(`projects/PROJECT_ID/secrets/SECRET_NAME/versions/42`) — IAM cannot restrict access to a subset
of versions.

The GCP gotcha: the IAM binding is on the Secret resource (`google_secret_manager_secret_iam_member`),
not on a version. But the actual payload lives in a `google_secret_manager_secret_version` resource.
These are two separate Terraform resources with separate lifecycle management. A
`terraform destroy` on the secret resource orphans the version unless you order destroys carefully.

---

## Testing Approach

### `terraform test` (native, Terraform >= 1.6)

Each module will have a `tests/` directory with `.tftest.hcl` files that exercise the module
against a real provider. `terraform test` handles the `plan → apply → assertions → destroy`
lifecycle natively.

**Current status:** Tests are not yet committed. Writing a runnable `terraform test` suite
requires live cloud credentials scoped to a disposable environment (a dedicated Azure subscription
or GCP project, not a shared one). The credential setup and OIDC-based CI wiring are not yet
automated. Committing test files that cannot run without undocumented manual setup would be
misleading — so they are deferred until that infrastructure exists.

**Why not terratest?** Terratest (Go) gives you more flexible assertions and parallel test
execution, but it adds a Go toolchain dependency and the `apply/destroy` lifecycle is manual.
For module-level testing, `terraform test`'s built-in lifecycle management is the right fit.
Terratest makes more sense for integration tests that span multiple modules and need custom
assertions (e.g., "the AKS API server is reachable from within the VNet").

The next step is wiring GitHub Actions with OIDC federated credentials to a sandboxed Azure
subscription and GCP project and committing `.tftest.hcl` files per module — the structure
above is already designed for that path.

---

## Versioning Strategy

Modules in this repo follow [Semantic Versioning](https://semver.org/). The table below defines
what counts as each type of change from a **consumer** perspective:

| Change | Version bump |
|---|---|
| New optional variable with a default | PATCH |
| New output | PATCH |
| New optional resource behind a `create_X` flag | MINOR |
| New required variable (no default) | MAJOR |
| Removed variable or output | MAJOR |
| Renamed variable or output | MAJOR |
| Resource type change that forces re-creation in consumer state | MAJOR |

Tags are prefixed with `v`: `v1.0.0`, `v1.2.3`.

Consumers should pin to a tag, not to `main`:

```hcl
module "aks" {
  source = "git::https://github.com/jithin2/terraform-portfolio.git//modules/azure/aks-cluster?ref=v1.2.0"
}
```

To centralise the ref across multiple modules from this repo:

```hcl
locals {
  module_ref = "v1.2.0"
}

module "aks" {
  source = "git::https://github.com/jithin2/terraform-portfolio.git//modules/azure/aks-cluster?ref=${local.module_ref}"
}

module "vnet" {
  source = "git::https://github.com/jithin2/terraform-portfolio.git//modules/azure/vnet?ref=${local.module_ref}"
}
```

**What pinning to a tag protects you from:** output renames, new required variables, and
resource type changes won't silently break your stack. You see the impact only when you
explicitly change the ref and run `terraform init`.

**What it does not protect you from:** provider version drift. If `~> 4.0` for azurerm allows a
4.x release that introduces a breaking change, you'll see it on the next `terraform init -upgrade`.
Module READMEs call out known provider-version sensitivities.

---

## Using the Examples

The `examples/` directory contains complete, wirable configurations that demonstrate how modules
compose:

| Example | What it demonstrates |
|---|---|
| `examples/azure-complete` | VNet + AKS + Key Vault wired end-to-end; managed identity delegation chain fully assembled |
| `examples/gcp-complete` | VPC + GKE + Secret Manager wired end-to-end; Workload Identity chain fully assembled |
| `examples/multicloud` | Same logical application deployed on both clouds using the shared naming module |

Examples are **not production-ready** — they use minimal configuration to show module
composition clearly. Treat them as living documentation of the expected call signature for each
module, not as deployable infrastructure.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

---

*This repo was built as a public demonstration of enterprise Terraform patterns.
All cloud resource configurations represent real-world design decisions, not tutorial approximations.*
