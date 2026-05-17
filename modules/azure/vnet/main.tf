locals {
  # Build a flat map of { "subnetname-rulename" => rule + nsg_name } for
  # azurerm_network_security_rule. Using a separate resource (not inline rules)
  # prevents Terraform plan conflicts when rules are added independently of the NSG.
  nsg_rules = merge([
    for subnet_name, subnet in var.subnets : {
      for rule in lookup(subnet, "nsg_rules", []) :
      "${subnet_name}-${rule.name}" => merge(rule, { nsg_name = subnet_name })
      if lookup(subnet, "create_nsg", true)
    }
  ]...)
}

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.address_space
  dns_servers         = var.dns_servers

  tags = var.tags
}

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                                          = each.key
  resource_group_name                           = var.resource_group_name
  virtual_network_name                          = azurerm_virtual_network.this.name
  address_prefixes                              = [each.value.address_prefix]
  service_endpoints                             = lookup(each.value, "service_endpoints", [])
  private_endpoint_network_policies             = lookup(each.value, "private_endpoint_network_policies", "Disabled")

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [each.value.delegation] : []
    content {
      name = delegation.value.service_name
      service_delegation {
        name    = delegation.value.service_name
        actions = delegation.value.actions
      }
    }
  }
}

resource "azurerm_network_security_group" "this" {
  for_each = { for k, v in var.subnets : k => v if lookup(v, "create_nsg", true) }

  name                = "${each.key}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

resource "azurerm_network_security_rule" "this" {
  for_each = local.nsg_rules

  name                        = each.value.name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.this[each.value.nsg_name].name
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = { for k, v in var.subnets : k => v if lookup(v, "create_nsg", true) }

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}
