# TODO(Step 3): Implement variables.
#
# variable "project_id" { type = string }
# variable "location"   { type = string, description = "Region or zone. Regional clusters (multi-zone) preferred for production." }
# variable "cluster_name" { type = string }
#
# variable "network"    { type = string, description = "VPC network self_link or name." }
# variable "subnetwork" { type = string, description = "Subnetwork self_link or name for nodes." }
#
# variable "pods_secondary_range_name" {
#   type        = string
#   description = "Name of the secondary IP range on the subnet for pods. Must already exist."
# }
# variable "services_secondary_range_name" {
#   type        = string
#   description = "Name of the secondary IP range on the subnet for services. Must already exist."
# }
#
# variable "master_cidr" {
#   type        = string
#   description = "CIDR for the master network (/28 required). Must not overlap node, pod, services, or peered VPC ranges."
#   validation {
#     condition     = can(regex("/28$", var.master_cidr))
#     error_message = "master_cidr must be a /28 prefix (GKE requirement)."
#   }
# }
#
# variable "private_cluster_config" {
#   type = object({
#     enable_private_nodes    = optional(bool, true)
#     enable_private_endpoint = optional(bool, false)  # true = no public master endpoint
#   })
#   default = { enable_private_nodes = true, enable_private_endpoint = false }
# }
#
# variable "master_authorized_networks" {
#   description = "CIDRs allowed to reach the master API server. Empty list = no external access (when private endpoint enabled)."
#   type = list(object({
#     cidr_block   = string
#     display_name = string
#   }))
#   default = []
# }
#
# variable "release_channel" {
#   type    = string
#   default = "REGULAR"
#   validation {
#     condition     = contains(["RAPID", "REGULAR", "STABLE", "UNSPECIFIED"], var.release_channel)
#     error_message = "release_channel must be RAPID, REGULAR, STABLE, or UNSPECIFIED."
#   }
# }
#
# variable "min_master_version" {
#   type        = string
#   default     = null
#   description = "Minimum master version. null = channel default. Specify only to prevent channel from upgrading below a known-good version."
# }
#
# variable "node_pools" {
#   description = "Map of node pool configs. Key is the pool name."
#   type = map(object({
#     machine_type    = string
#     disk_size_gb    = optional(number, 100)
#     disk_type       = optional(string, "pd-ssd")
#     min_node_count  = number
#     max_node_count  = number
#     preemptible     = optional(bool, false)
#     spot            = optional(bool, false)
#     node_taints = optional(list(object({
#       key    = string
#       value  = string
#       effect = string  # NO_SCHEDULE, NO_EXECUTE, PREFER_NO_SCHEDULE
#     })), [])
#     node_labels = optional(map(string), {})
#   }))
# }
#
# variable "create_node_sa" {
#   type        = bool
#   default     = true
#   description = "Create a dedicated minimal service account for nodes. Recommended — avoids using the default compute SA."
# }
#
# variable "labels" { type = map(string), default = {} }
