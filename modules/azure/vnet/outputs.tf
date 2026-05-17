output "vnet_id" {
  description = "Resource ID of the Virtual Network."
  value       = azurerm_virtual_network.this.id
}

output "vnet_name" {
  description = "Name of the Virtual Network."
  value       = azurerm_virtual_network.this.name
}

output "vnet_address_space" {
  description = "List of CIDR blocks assigned to the VNet."
  value       = azurerm_virtual_network.this.address_space
}

output "subnet_ids" {
  description = "Map of logical subnet name to subnet resource ID. Pass values as vnet_subnet_id in the AKS cluster module."
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}

output "subnet_address_prefixes" {
  description = "Map of logical subnet name to CIDR prefix. Useful when constructing NSG rules in calling modules."
  value       = { for k, v in azurerm_subnet.this : k => v.address_prefixes[0] }
}

output "nsg_ids" {
  description = "Map of logical subnet name to NSG resource ID. Only includes subnets where create_nsg = true."
  value       = { for k, v in azurerm_network_security_group.this : k => v.id }
}
