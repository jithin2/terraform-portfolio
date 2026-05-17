# TODO(Step 2): Implement variables.
#
# variable "resource_group_name" { type = string }
# variable "location"            { type = string }
# variable "vnet_name"           { type = string }
#
# variable "address_space" {
#   description = "List of CIDR blocks for the VNet. Hub/spoke consumers typically pass a single /16 or /22."
#   type        = list(string)
#   validation {
#     condition     = length(var.address_space) > 0
#     error_message = "address_space must contain at least one CIDR block."
#   }
# }
#
# variable "dns_servers" {
#   description = "Custom DNS server IPs. Empty list = Azure-provided DNS. Set to private resolver IPs for hub/spoke."
#   type        = list(string)
#   default     = []
# }
#
# variable "subnets" {
#   description = "Map of subnet configurations. Key is used as the logical subnet name in outputs."
#   type = map(object({
#     address_prefix                              = string
#     service_endpoints                           = optional(list(string), [])
#     private_endpoint_network_policies           = optional(string, "Disabled")  # Disabled required for PEP subnets
#     delegation                                  = optional(object({ service_name = string, actions = list(string) }), null)
#     create_nsg                                  = optional(bool, true)
#     nsg_rules = optional(list(object({
#       name                       = string
#       priority                   = number
#       direction                  = string  # Inbound or Outbound
#       access                     = string  # Allow or Deny
#       protocol                   = string
#       source_port_range          = string
#       destination_port_range     = string
#       source_address_prefix      = string
#       destination_address_prefix = string
#     })), [])
#   }))
# }
#
# variable "tags" { type = map(string), default = {} }
