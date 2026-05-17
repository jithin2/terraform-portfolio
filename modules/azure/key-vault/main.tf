# TODO(Step 2): Implement Key Vault resources.
#
# Resources:
#
#   data "azurerm_client_config" "current"
#     · Used to get the current tenant_id and caller object_id at plan time.
#       Required by azurerm_key_vault.tenant_id.
#
#   azurerm_key_vault "this"
#     · enable_rbac_authorization = true (module default and recommendation)
#       RBAC mode: access governed by standard Azure role assignments (Key Vault Secrets User,
#       Key Vault Secrets Officer, Key Vault Administrator). Clear separation of management
#       plane vs data plane roles.
#       Vault access policies (legacy): avoid in new deployments — limited to 1024 policies
#       per vault and cannot be managed with Azure PIM.
#     · soft_delete_retention_days: default 90 (max). Cannot be reduced once set.
#       purge_protection_enabled: default true for production. Once enabled, cannot be
#       disabled and the vault cannot be force-purged before retention period.
#     · network_acls: default_action = "Deny", bypass = "AzureServices"
#       In private-endpoint mode: ip_rules = [], virtual_network_subnet_ids = []
#       In firewall mode (no PEP): add subnet IDs to virtual_network_subnet_ids.
#       These two patterns are mutually exclusive — do not mix them.
#
#   azurerm_private_endpoint "kv" (count = var.enable_private_endpoint ? 1 : 0)
#     · Subnet must be a dedicated PEP subnet with private_endpoint_network_policies = "Disabled"
#     · private_service_connection: subresource_names = ["vault"]
#
#   azurerm_private_dns_zone_virtual_network_link "kv" (count = same condition)
#     · Only needed if the DNS zone is not already linked to the VNet.
#     · Consider making this conditional on a separate var to avoid conflicts when the
#       zone is linked by a hub networking module.
#
# Key design decisions:
#   - Role assignments are NOT created inside this module. The module outputs vault_id
#     and vault_uri; callers create role assignments using azurerm_role_assignment.
#     Reason: the set of identities that need access is caller-specific, not module-specific.
#   - purge_protection_enabled defaults to true. Callers must explicitly set it to false
#     for dev/test environments where vaults need to be fully deleted.
