# TODO(Step 2): Implement variables.
#
# variable "resource_group_name" { type = string }
# variable "location"            { type = string }
# variable "name"                { type = string, description = "Key Vault name. Globally unique, 3-24 chars, alphanumeric and hyphens." }
#
# variable "sku_name" {
#   type    = string
#   default = "standard"
#   validation {
#     condition     = contains(["standard", "premium"], var.sku_name)
#     error_message = "sku_name must be standard or premium."
#   }
# }
#
# variable "soft_delete_retention_days" {
#   type    = number
#   default = 90
#   validation {
#     condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
#     error_message = "soft_delete_retention_days must be between 7 and 90."
#   }
# }
#
# variable "purge_protection_enabled" {
#   type        = bool
#   default     = true
#   description = "Once enabled, cannot be disabled and vault cannot be force-purged. Set false only for dev/test."
# }
#
# variable "enable_rbac_authorization" {
#   type        = bool
#   default     = true
#   description = "Use Azure RBAC for data plane access. Recommended over vault access policies for new deployments."
# }
#
# variable "network_acls" {
#   description = "Network ACLs for the vault. default_action = Deny is recommended. In PEP mode, leave ip_rules and subnet_ids empty."
#   type = object({
#     default_action             = optional(string, "Deny")
#     bypass                     = optional(string, "AzureServices")
#     ip_rules                   = optional(list(string), [])
#     virtual_network_subnet_ids = optional(list(string), [])
#   })
#   default = {}
# }
#
# variable "enable_private_endpoint" {
#   type    = bool
#   default = false
# }
# variable "private_endpoint_subnet_id" {
#   type    = string
#   default = null
#   description = "Required when enable_private_endpoint = true. Must be a PEP subnet with network policies disabled."
# }
# variable "private_dns_zone_id" {
#   type    = string
#   default = null
#   description = "Private DNS zone ID for privatelink.vaultcore.azure.net. Required when enable_private_endpoint = true."
# }
# variable "link_private_dns_zone_to_vnet" {
#   type        = bool
#   default     = false
#   description = "Create a VNet link for the private DNS zone. Set false if a hub networking module already links it."
# }
# variable "vnet_id" {
#   type    = string
#   default = null
#   description = "VNet ID for DNS zone link. Required when link_private_dns_zone_to_vnet = true."
# }
#
# variable "tags" { type = map(string), default = {} }
