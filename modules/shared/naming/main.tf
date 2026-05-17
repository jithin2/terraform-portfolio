# TODO(Step 2): Implement naming convention using locals only — no provider resources.
#
# Core logic (pure string computation, no state):
#
#   locals {
#     # Base prefix:  "prod-eus-payments"
#     prefix = join(var.separator, [var.environment, var.region_abbreviation, var.application])
#
#     # Full name:    "prod-eus-payments-aks"
#     name = join(var.separator, [local.prefix, var.resource_type])
#
#     # Slug (hyphens stripped): "prodeuspayments aks" → used for resources that forbid
#     # hyphens (Azure storage accounts, GCS bucket names, some IAM IDs).
#     slug = replace(local.name, "-", "")
#
#     # Standard label/tag map — apply to all resources in the calling module.
#     labels = {
#       environment = var.environment
#       region      = var.region_abbreviation
#       application = var.application
#       managed_by  = "terraform"
#     }
#   }
#
# Why locals only:
#   Naming is a pure computation with no side effects. A resource block would add
#   unnecessary state entries that churn on every plan even when nothing changes.
#
# Precondition to add on the slug output:
#   Azure storage account names are globally unique and capped at 24 characters.
#   Emit a plan-time error (lifecycle precondition) if slug exceeds 24 chars rather
#   than letting the apply fail with an unhelpful ARM error.
