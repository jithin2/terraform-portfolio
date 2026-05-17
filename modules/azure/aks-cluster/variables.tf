# TODO(Step 2): Implement variables with descriptions and validation blocks.
#
# variable "resource_group_name" { type = string, description = "..." }
# variable "location"            { type = string, description = "..." }
# variable "cluster_name"        { type = string, description = "..." }
#
# variable "kubernetes_version" {
#   type        = string
#   default     = null
#   description = "Kubernetes version. null = AKS-recommended latest. Pin for production."
# }
#
# variable "sku_tier" {
#   type    = string
#   default = "Standard"
#   validation {
#     condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
#     error_message = "sku_tier must be Free, Standard, or Premium."
#   }
# }
#
# variable "private_cluster_enabled" { type = bool, default = false }
# variable "private_dns_zone_id" {
#   type        = string
#   default     = null
#   description = <<-EOT
#     Private DNS zone ID for the API server. Required when private_cluster_enabled = true.
#     "System"  = Azure-managed zone in the MC_ resource group (simpler, less control).
#     "None"    = No DNS management (you manage the A record).
#     Resource ID = BYO zone (recommended for hub/spoke — link to hub VNet).
#   EOT
# }
#
# variable "default_node_pool" {
#   description = "Configuration for the system node pool (one per cluster, cannot be deleted)."
#   type = object({
#     name                = string
#     vm_size             = string
#     min_count           = number
#     max_count           = number
#     os_disk_type        = optional(string, "Ephemeral")
#     os_disk_size_gb     = optional(number, null)
#     vnet_subnet_id      = string
#     only_critical_addons = optional(bool, true)
#   })
# }
#
# variable "user_node_pools" {
#   description = "Map of user node pools. Key is the pool name (max 12 chars, alphanumeric)."
#   type = map(object({
#     vm_size         = string
#     min_count       = number
#     max_count       = number
#     vnet_subnet_id  = string
#     os_disk_type    = optional(string, "Ephemeral")
#     node_taints     = optional(list(string), [])
#     node_labels     = optional(map(string), {})
#   }))
#   default = {}
# }
#
# variable "network_profile" {
#   description = "AKS network profile. Defaults to Azure CNI with Calico network policy."
#   type = object({
#     network_plugin     = optional(string, "azure")
#     network_policy     = optional(string, "calico")
#     service_cidr       = optional(string, "172.16.0.0/16")
#     dns_service_ip     = optional(string, "172.16.0.10")
#     load_balancer_sku  = optional(string, "standard")
#   })
#   default = {}
# }
#
# variable "identity_type" {
#   type    = string
#   default = "SystemAssigned"
#   validation {
#     condition     = contains(["SystemAssigned", "UserAssigned"], var.identity_type)
#     error_message = "identity_type must be SystemAssigned or UserAssigned."
#   }
# }
# variable "kubelet_identity_id" {
#   type        = string
#   default     = null
#   description = "Resource ID of the user-assigned managed identity for the kubelet. Required when identity_type = UserAssigned."
# }
#
# variable "oidc_issuer_enabled"        { type = bool, default = true }
# variable "workload_identity_enabled"  { type = bool, default = true }
#
# variable "tags" { type = map(string), default = {} }
