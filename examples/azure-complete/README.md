# examples/azure-complete

<!-- TODO(Step 4): Expand after example is implemented. -->

## What This Demonstrates

End-to-end Azure stack: VNet + AKS (private cluster) + Key Vault (private endpoint).

Key wiring points:
- Kubelet managed identity assigned `Key Vault Secrets User` on the vault
- AKS OIDC issuer URL available as an output for downstream federated credential setup
- Private DNS zones linked to the VNet for both the AKS API server and Key Vault endpoint

## Usage

```bash
terraform init
terraform plan -var="resource_group_name=rg-demo"
terraform apply -var="resource_group_name=rg-demo"
```

## Not Production-Ready

This example uses a local backend and minimal configuration. For production:
- Use `azurerm` backend (storage account + container) for state
- Enable diagnostic settings on AKS and Key Vault
- Use a dedicated service principal with scoped permissions, not az login credentials
