# TODO(Step 3): Implement variables.
#
# variable "project_id"    { type = string }
# variable "network_name"  { type = string }
#
# variable "routing_mode" {
#   type    = string
#   default = "REGIONAL"
#   validation {
#     condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
#     error_message = "routing_mode must be REGIONAL or GLOBAL."
#   }
# }
#
# variable "subnets" {
#   description = "Map of subnets. Key is the logical name used in outputs."
#   type = map(object({
#     ip_cidr_range           = string
#     region                  = string
#     private_ip_google_access = optional(bool, true)
#     secondary_ip_ranges = optional(list(object({
#       range_name    = string
#       ip_cidr_range = string
#     })), [])
#   }))
# }
#
# variable "create_nat" {
#   type        = bool
#   default     = false
#   description = "Create a Cloud NAT gateway for outbound internet access from private nodes."
# }
# variable "nat_router_region" {
#   type        = string
#   default     = null
#   description = "Region for the Cloud Router and NAT. Required when create_nat = true."
# }
# variable "nat_log_filter" {
#   type    = string
#   default = "ERRORS_ONLY"
#   validation {
#     condition     = contains(["ERRORS_ONLY", "TRANSLATIONS_ONLY", "ALL"], var.nat_log_filter)
#     error_message = "nat_log_filter must be ERRORS_ONLY, TRANSLATIONS_ONLY, or ALL."
#   }
# }
#
# variable "labels" { type = map(string), default = {} }
