# azure/key-vault

## Purpose

Creates an Azure Key Vault configured for enterprise use:
- RBAC authorization mode (not vault access policies)
- Purge protection and configurable soft-delete retention
- Optional private endpoint with DNS zone linking
- Network ACL default-deny (bypass AzureServices only)

This module does **not** create role assignments — that is the caller's responsibility.
It exports `vault_id` so callers can assign `Key Vault Secrets User` or
`Key Vault Secrets Officer` to the specific identities that need access.

## Inputs

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `resource_group_name` | Resource group | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `name` | Vault name (globally unique, 3-24 chars) | `string` | — | yes |
| `sku_name` | `standard` or `premium` | `string` | `"standard"` | no |
| `soft_delete_retention_days` | 7–90 days | `number` | `90` | no |
| `purge_protection_enabled` | Prevent force-purge | `bool` | `true` | no |
| `enable_rbac_authorization` | Use RBAC for data plane | `bool` | `true` | no |
| `network_acls` | Firewall config | `object` | default-deny | no |
| `enable_private_endpoint` | Create PEP | `bool` | `false` | no |
| `private_endpoint_subnet_id` | PEP subnet ID | `string` | `null` | no |
| `private_dns_zone_id` | DNS zone for privatelink.vaultcore.azure.net | `string` | `null` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| `vault_id` | Key Vault resource ID |
| `vault_uri` | Key Vault URI |
| `vault_name` | Key Vault name |
| `private_endpoint_id` | PEP resource ID (null if disabled) |
| `private_endpoint_ip` | PEP private IP (null if disabled) |

## Usage

```hcl
module "kv" {
  source = "../../azure/key-vault"

  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus"
  name                = module.naming.slug  # no hyphens, max 24 chars

  enable_private_endpoint    = true
  private_endpoint_subnet_id = module.vnet.subnet_ids["pep"]
  private_dns_zone_id        = azurerm_private_dns_zone.kv.id

  tags = module.naming.labels
}

# Caller assigns roles — module does not
resource "azurerm_role_assignment" "aks_kv_secrets_user" {
  scope                = module.kv.vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.aks.kubelet_identity.object_id
}
```

## Gotchas

- **RBAC vs access policies are mutually exclusive.** Once `enable_rbac_authorization = true`
  is set and applied, you cannot add vault access policies and vice versa. This module
  defaults to RBAC. Do not set both.
- **Data plane vs management plane roles.** `Key Vault Contributor` is a management plane role
  (CRUD on the vault resource). It grants zero data plane access. An identity with Contributor
  cannot read secrets. Use `Key Vault Secrets User` for read-only secret access.
- **`purge_protection_enabled = true` is irreversible.** Once set on a vault, it cannot be
  removed. A soft-deleted vault with purge protection cannot be force-deleted before the
  retention period expires. Blocked vault names cannot be reused until the retention period ends.
  Set `false` for ephemeral dev environments.
- **DNS zone linking.** If you use a hub/spoke topology where the private DNS zone is already
  linked to the hub VNet, set `link_private_dns_zone_to_vnet = false`. Creating a duplicate
  link causes a `Conflict` error that is confusing to diagnose.
