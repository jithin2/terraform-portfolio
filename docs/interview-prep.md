# Interview prep — hardest questions this repo invites

Five questions an experienced Terraform interviewer will reach for after
reviewing this repo. Each answer is written the way you should deliver it
verbally: direct claim first, then the reasoning, then the tradeoff you
consciously accepted.

---

## Q1 — "You use `for_each` on `user_node_pools` and on IAM bindings in the secret-manager module. Walk me through what happens to Terraform state if you had used `count` instead and someone removes the first item from the list."

**Why they're asking:**
This is one of the most common footguns in production Terraform. It destroys
and recreates real infrastructure silently. If you can explain it clearly, you
demonstrate that you understand how Terraform models state — not just how to
write resources.

**How to answer:**

`count` addresses resources by index: `azurerm_kubernetes_cluster_node_pool.user[0]`,
`[1]`, `[2]`. The index is determined by position in the list at the time
`terraform plan` runs.

If a caller removes the first pool from a list of three, the list shifts:
- What was `pool_a` at index 0 is gone
- What was `pool_b` at index 1 is now at index 0
- What was `pool_c` at index 2 is now at index 1

Terraform compares the new plan to the state file. The state has `[0]`, `[1]`,
`[2]`. The new plan also has `[0]` and `[1]` — but with different
configurations (because the resources shifted). Terraform sees:

```
# azurerm_kubernetes_cluster_node_pool.user[0]: must be replaced
# azurerm_kubernetes_cluster_node_pool.user[1]: must be replaced
# azurerm_kubernetes_cluster_node_pool.user[2]: will be destroyed
```

Three operations on two resources that were never supposed to change.
In production, this destroys workload-carrying node pools.

`for_each` with a map uses the key as the state address:
`azurerm_kubernetes_cluster_node_pool.user["app"]`,
`["batch"]`, `["gpu"]`. Remove `"app"` from the map and Terraform plans:

```
# azurerm_kubernetes_cluster_node_pool.user["app"]: will be destroyed
```

Only the resource you intended to remove is touched.

The same argument applies to `iam_bindings_map` in the secret-manager module.
The input is a `list(object(...))` because it's more ergonomic to write as
a list in a `tfvars` file. But iterating over a list with `for_each` is not
valid — `for_each` requires a map or set. So the module builds a stable key:

```hcl
iam_bindings_map = {
  for b in var.iam_bindings :
  "${b.secret_key}--${b.role}--${b.member}" => b
}
```

That composite key is stable regardless of order in the source list. Remove
a binding from the middle of the list and only that binding is destroyed.

**Tradeoff accepted:** the composite key must be unique. If someone somehow
adds two identical bindings (same secret, role, and member), the `for_each`
silently takes the last value. In practice IAM bindings are idempotent so
this is not harmful, but it is a subtle edge you should name.

---

## Q2 — "You have `ignore_changes = [kubernetes_version]` in the AKS lifecycle block. Explain why, and then tell me a scenario where using `ignore_changes` would mask a real problem rather than solve a legitimate one."

**Why they're asking:**
`ignore_changes` is one of those Terraform escape hatches that solves a real
problem but also lets engineers paper over configuration drift they should
actually fix. A senior reviewer wants to know you understand the distinction.

**How to answer:**

AKS auto-upgrades patch versions via maintenance windows and release channels —
this is a managed service feature you generally want. If Terraform tracks
`kubernetes_version` and the cluster auto-upgrades from `1.29.3` to `1.29.8`,
the next `terraform plan` shows:

```
~ kubernetes_version = "1.29.3" -> "1.29.3"  # (forces replacement)
```

Terraform wants to downgrade the cluster back to the pinned version. In AKS,
`kubernetes_version` is a `ForceNew` attribute on the default node pool's
`orchestrator_version` — meaning Terraform would destroy and recreate the node
pool to "fix" the drift. That destroys running workloads to enforce a version
that the cluster's own maintenance window already moved past.

`ignore_changes` says: "I am not tracking this attribute. If it drifts, I
accept the drift." The platform engineer owns major and minor version upgrades
(which are intentional, planned changes to the Terraform code). The cluster
manages its own patch version within that minor.

**When `ignore_changes` masks a real problem:**

Imagine a team mistakenly sets `kubernetes_version = "1.28.0"` on a cluster
that has already upgraded to `1.29.x`. The `ignore_changes` means Terraform
never surfaces this discrepancy. The team believes the cluster is on `1.28.0`
because that's what the Terraform code says. It is actually on `1.29.5`. When
they try to add a node pool with `orchestrator_version = "1.28.0"` (a minor
version the cluster no longer supports), the apply fails — but confusingly,
because the declared state was masked rather than corrected.

The discipline is: `ignore_changes` is correct for attributes that a managed
service controls autonomously (patch versions, auto-scaling counts). It is
wrong for attributes that represent intentional configuration that a human
set and should own. If the drift is intentional by the service, ignore it.
If the drift means something is out of spec, surface it.

---

## Q3 — "Why do you enforce `identity_type == UserAssigned → control_plane_identity_id != null` as a `precondition` in the lifecycle block rather than as a `validation` block on the `identity_type` variable?"

**Why they're asking:**
Variable `validation` and `precondition` look similar but have fundamentally
different evaluation semantics. This question tests whether you understand
the distinction or just reached for the tool that worked.

**How to answer:**

`variable validation` blocks can only reference the variable's own value.
They evaluate at parse time, before any other inputs are resolved. This means
inside a `validation` block for `var.identity_type`, you cannot reference
`var.control_plane_identity_id` — that would be a cross-variable reference,
which Terraform rejects:

```hcl
variable "identity_type" {
  validation {
    # This fails at parse time:
    condition = var.identity_type == "SystemAssigned" || var.control_plane_identity_id != null
    #                                                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    #    Error: Invalid reference — can only reference the variable itself
  }
}
```

`precondition` evaluates at plan time, after all inputs are resolved and all
`locals` are computed. At that point, every variable is available. This is
what makes the cross-variable constraint possible:

```hcl
lifecycle {
  precondition {
    condition     = var.identity_type == "SystemAssigned" || var.control_plane_identity_id != null
    error_message = "control_plane_identity_id must be provided when identity_type is UserAssigned."
  }
}
```

**The practical difference:** a `validation` error fires as soon as Terraform
parses the module, before any planning work happens. A `precondition` fires
during `terraform plan`, after all values are computed. For constraints that
can be fully expressed from a single variable (e.g., `sku_tier must be Free,
Standard, or Premium`), use `validation` — the earlier the error, the faster
the feedback. For constraints that span multiple inputs or depend on computed
values, `precondition` is the right tool.

There is a third option: `postcondition`, which fires after the resource is
created and can reference the resource's actual attributes. That is appropriate
for asserting invariants about what the provider created (e.g., "the cluster
must have a private endpoint after creation"). Not used here because the
constraints are about inputs, not outputs.

---

## Q4 — "The `shared/naming` module outputs both `name` and `slug`. The `azure-complete` example uses `slug` for the Key Vault name, not `name`. Why? What breaks if you use `name` instead?"

**Why they're asking:**
This tests whether you wrote the naming module to solve a real problem you
encountered or just templated a naming convention. The slug distinction only
makes sense if you've hit the constraints it exists to work around.

**How to answer:**

`name` is the full hyphenated string: `prod-eus-payments-kv` (20 chars).
`slug` strips the separator: `prodeuspaymentskv` (17 chars).

Azure Key Vault names have three constraints that create the conflict:
1. Maximum 24 characters
2. Alphanumeric and hyphens only — hyphens are allowed
3. Globally unique across all Azure subscriptions

Key Vault names themselves allow hyphens, so `name` would work for Key Vault.
The real constraint that forces `slug` is Azure Storage Account names:
- Maximum 24 characters
- **Alphanumeric only — no hyphens**
- Globally unique

If the naming module outputs only `name`, callers that need to create a storage
account (Terraform backend, Azure Functions storage, Azure ML workspace) have
no path to a valid name without doing string manipulation themselves. `slug`
gives them a valid storage account name derived from the same naming convention.

The Key Vault example specifically uses `slug` to demonstrate this output
exists and is intentional — but in the example, either `name` or `slug` would
be valid for the vault. The slug matters most when the same module call needs
to name both a Key Vault and its associated storage account under the same
naming root.

**What breaks if you use `name` for a storage account:**

Terraform plan produces:
```
Error: creating Storage Account: ... storage account name "prod-eus-pay-sa"
is invalid: must consist of only lowercase letters and numbers
```

The provider validates this at apply time, not plan time — so the failure
arrives after the resource group is already created, partway through the apply.

**Tradeoff in the naming module:** `slug` drops the separator entirely, which
means two different naming inputs could theoretically produce the same slug
(e.g., `prode-uspay` and `prod-euspay` both slug to `prodeuspay`). In
practice, the naming inputs (environment, region, application, resource type)
are controlled values with known cardinality, so collision is a theoretical
risk but not a real operational one. If you needed to guarantee uniqueness
of the slug, you would add a validation or a suffix.

---

## Q5 — "Your GCP secret-manager module uses `google_secret_manager_secret_iam_member` (additive) not `google_secret_manager_secret_iam_binding` (authoritative). Give me a case where your choice is wrong, and explain how you'd know."

**Why they're asking:**
The additive vs authoritative IAM choice in GCP is a design decision with
real operational consequences. Most engineers know one is additive and one is
authoritative but cannot articulate when each is correct. The failure mode
of the wrong choice in production is either "someone lost access unexpectedly"
or "someone retained access they should have lost" — both are serious.

**How to answer:**

`google_secret_manager_secret_iam_binding` is **authoritative for a role** on
a resource. When Terraform manages a binding for `roles/secretmanager.secretAccessor`
on `my-secret`, it asserts: "these members and only these members have this
role." Any binding that exists in GCP but is not in the Terraform state for
that role is removed on the next apply.

`google_secret_manager_secret_iam_member` is **additive**. Terraform manages
only the bindings it created and leaves all others alone.

**Why additive is correct for this module:**

GKE Workload Identity setup automatically creates IAM bindings. When you
annotate a Kubernetes service account with `iam.gke.io/gcp-service-account`,
GKE or the WI controller adds the SA as a member with
`roles/iam.workloadIdentityUser` on the GCP service account. Separately, a
developer might use the GCP Console or gcloud to grant emergency access to a
secret during an incident.

If this module used `iam_binding`, the next `terraform apply` would remove
every binding not declared in Terraform — including the Workload Identity
binding GKE created, and the emergency access the on-call engineer granted.

**When `iam_binding` is correct:**

When this module is the declared sole owner of access to a secret and you
need an audit guarantee that no binding exists outside of Terraform. This is
the correct pattern for a "secure secrets" module in a compliance context —
PCI, SOC 2 — where you must be able to prove that access is fully IaC-managed
and no out-of-band bindings exist.

In that case, you also need to be sure that any tooling (GKE WI, break-glass
emergency access) either goes through the Terraform module or is explicitly
accepted as drift.

**How you'd know you made the wrong choice in production:**

With `iam_member` (additive) and a forgotten out-of-band binding: you run
`terraform plan` and it shows no changes. The extra binding exists in GCP
but Terraform doesn't know about it. You would only discover it with a
manual `gcloud secrets get-iam-policy` or a separate compliance audit tool.

With `iam_binding` (authoritative) applied incorrectly: you apply and GKE
Workload Identity stops working for all pods accessing that secret within
minutes, because the WI binding was just removed. Kubernetes will log 401s
from the metadata server. That is a production incident.

The signal that you chose wrong with `iam_binding`: alerts fire immediately
after an apply that "only added an IAM binding." The signal that you chose
wrong with `iam_member`: an audit finds a binding that has been there for
18 months that nobody owns.

---

## Local test checklist

Things to verify before opening a PR or claiming a module is ready.

### Format and syntax
```bash
# Run from repo root — catches all modules and examples
terraform fmt -check -diff -recursive .

# Validate each module independently (no backend needed)
for dir in modules/azure/aks-cluster modules/azure/key-vault modules/azure/vnet \
           modules/gcp/gke-cluster modules/gcp/secret-manager modules/gcp/vpc \
           modules/shared/naming; do
  echo "=== $dir ==="
  terraform -chdir="$dir" init -backend=false -input=false
  terraform -chdir="$dir" validate
done
```

### Linting
```bash
# tflint uses the .tflint.hcl at the repo root
# --init downloads provider rulesets on first run (azurerm + google plugins)
tflint --init
tflint --format compact --recursive
```

### Security scan
```bash
# Checkov replaces archived tfsec
checkov --directory . --framework terraform --compact
```

### Pre-commit (all checks in one command)
```bash
# Runs fmt + validate + tflint + checkov on all changed files
pre-commit run --all-files

# Or just on staged files (faster during active development)
pre-commit run
```

### Manual review checklist

- [ ] Every `variable` has `description` and `type` (required by `terraform_documented_variables` and `terraform_typed_variables` tflint rules)
- [ ] Every `output` has `description` (required by `terraform_documented_outputs`)
- [ ] Every `versions.tf` has both `required_version` and `required_providers` with version constraints
- [ ] `for_each` used instead of `count` for any resource that callers will add/remove items from
- [ ] `lifecycle { ignore_changes }` is commented with *why* (managed by the provider, not a mistake)
- [ ] `precondition` blocks cover cross-variable constraints that `validation` cannot express
- [ ] No hardcoded region strings, account IDs, or project IDs — all parameterised
- [ ] `tfvars` files are in `.gitignore` — only `*.tfvars.example` files are committed
- [ ] `.terraform.lock.hcl` is committed (pins provider versions) — not in `.gitignore`
