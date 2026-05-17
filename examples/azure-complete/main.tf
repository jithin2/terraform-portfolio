# TODO(Step 4): Wire vnet + aks-cluster + key-vault end-to-end.
#
# This example demonstrates:
#   1. Shared naming module consumed by all three Azure modules
#   2. VNet with subnet layout sized for AKS Azure CNI
#   3. Key Vault with private endpoint on the PEP subnet
#   4. AKS private cluster pointing its DNS to the BYO private DNS zone
#   5. Role assignments for the kubelet identity on Key Vault (caller-side, not in modules)
#   6. Output: OIDC issuer URL wired to a sample federated credential resource
#
# Module call order (dependency chain):
#   naming → vnet → key-vault → private DNS zone → aks-cluster → role assignments
#
# Provider block: use azurerm with features {} block.
# Backend block: leave as local for the example; note in README that production should
#   use azurerm backend (storage account + state locking).
