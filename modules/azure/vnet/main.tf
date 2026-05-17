# TODO(Step 2): Implement VNet resources.
#
# Resources:
#
#   azurerm_virtual_network "this"
#     · address_space from var.address_space (list of CIDR strings)
#     · dns_servers optional — pass custom DNS IPs for hub/spoke with private resolvers
#
#   azurerm_subnet (for_each over var.subnets)
#     · Key = logical subnet name (e.g., "aks-system", "aks-user", "pep")
#     · address_prefixes, service_endpoints, delegation blocks all from subnet config
#     · enforce_private_link_endpoint_network_policies — set per-subnet for PEP subnets
#     · NOTE: azurerm_subnet and azurerm_network_security_group_association cannot be
#       managed in the same resource block. Keep them separate.
#
#   azurerm_network_security_group (for_each over subnets that have nsg = true)
#     · Created once per subnet, not shared — avoids rule conflicts between subnets
#
#   azurerm_network_security_rule (for_each over a flattened map of rules per NSG)
#     · Flatten: { "subnet-rulename" => { nsg_name, priority, direction, access, ... } }
#     · Using a separate resource (not inline rules) avoids Terraform plan conflicts
#       when rules are added/removed independently of the NSG itself
#
#   azurerm_subnet_network_security_group_association (for_each over subnets with NSGs)
#
# Key design decisions:
#   - Subnets as a map (not list) ensures stable for_each keys. Renaming a subnet in
#     the map does NOT shift other subnets' addresses in the plan.
#   - Separate NSG per subnet (rather than one shared NSG) reflects enterprise practice:
#     each subnet has its own security boundary that can evolve independently.
#   - nsg_rules are optional per subnet. A PEP subnet may have no NSG rules at all.
