variable "resource_group_name" {
  description = "Name of the Azure resource group where the VNet is deployed."
  type        = string
}

variable "location" {
  description = "Azure region for the VNet (e.g., eastus, westeurope)."
  type        = string
}

variable "vnet_name" {
  description = "Name of the Virtual Network."
  type        = string
}

variable "address_space" {
  description = "List of CIDR blocks assigned to the VNet. Hub/spoke consumers typically pass a single /16 or /22."
  type        = list(string)

  validation {
    condition     = length(var.address_space) > 0
    error_message = "address_space must contain at least one CIDR block."
  }
}

variable "dns_servers" {
  description = "Custom DNS server IPs. Empty list = Azure-provided DNS. Set to private resolver IPs in hub/spoke topologies with a central DNS resolver."
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "Map of subnet configurations. Key is the logical subnet name used in all outputs."
  type = map(object({
    address_prefix                    = string
    service_endpoints                 = optional(list(string), [])
    private_endpoint_network_policies = optional(string, "Disabled")
    create_nsg                        = optional(bool, true)
    delegation = optional(object({
      service_name = string
      actions      = list(string)
    }), null)
    nsg_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), [])
  }))
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
