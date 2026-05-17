# TODO(Step 4): Wire the same logical application on both Azure and GCP using shared naming.
#
# This example demonstrates:
#   1. A single shared/naming module call per cloud (same env/app inputs, different resource_type)
#   2. The naming module produces comparable names across clouds:
#        Azure: prod-eus-payments-aks    GCP: prod-ue1-payments-gke
#   3. Azure stack: vnet + aks-cluster + key-vault
#   4. GCP stack: vpc + gke-cluster + secret-manager
#   5. Shared outputs showing the naming parity (for documentation purposes)
#
# Two provider blocks: azurerm + google, aliased if needed.
# Uses separate naming module calls per cloud since region abbreviations differ.
#
# Interview talking point: the shared/naming module does not enforce identical names
# across clouds (regions have different abbreviation conventions). What it enforces is
# a consistent *structure*. env-region-app-type on Azure corresponds to
# env-region-app-type on GCP — both produced by the same module, same inputs except region.
