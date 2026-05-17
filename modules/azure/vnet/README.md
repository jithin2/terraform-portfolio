# azure/vnet

<!-- TODO(Step 2): Expand after module is implemented. -->

## Purpose

Creates a hub/spoke-ready Azure Virtual Network with:
- Configurable subnets defined as a map (stable `for_each` addressing)
- One NSG per subnet (independent security boundaries)
- NSG rules as a separate resource type (avoids inline-rule conflicts with other rule managers)
- Custom DNS server support (for hub/spoke with Azure Private DNS Resolver)

## Inputs

<!-- TODO: Run `terraform-docs markdown table .` after variables.tf is complete. -->

| Name | Description | Type | Default | Required |
|---|---|---|---|---|
| `resource_group_name` | Resource group for the VNet | `string` | — | yes |
| `location` | Azure region | `string` | — | yes |
| `vnet_name` | VNet name | `string` | — | yes |
| `address_space` | List of CIDR blocks | `list(string)` | — | yes |
| `subnets` | Map of subnet configs (see schema) | `map(object)` | — | yes |
| `dns_servers` | Custom DNS IPs (empty = Azure DNS) | `list(string)` | `[]` | no |
| `tags` | Resource tags | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|---|---|
| `vnet_id` | VNet resource ID |
| `vnet_name` | VNet name |
| `vnet_address_space` | VNet CIDR list |
| `subnet_ids` | Map of subnet name → subnet ID |
| `subnet_address_prefixes` | Map of subnet name → CIDR |
| `nsg_ids` | Map of subnet name → NSG ID |

## Usage

```hcl
module "vnet" {
  source = "../../azure/vnet"

  resource_group_name = azurerm_resource_group.main.name
  location            = "eastus"
  vnet_name           = module.naming.name

  address_space = ["10.0.0.0/16"]

  subnets = {
    "aks-system" = {
      address_prefix    = "10.0.0.0/22"
      service_endpoints = ["Microsoft.ContainerRegistry"]
    }
    "aks-user" = {
      address_prefix = "10.0.4.0/22"
    }
    "pep" = {
      address_prefix                    = "10.0.8.0/24"
      private_endpoint_network_policies = "Disabled"
      create_nsg                        = false
    }
  }

  tags = module.naming.labels
}
```

## Gotchas

- **`private_endpoint_network_policies = "Disabled"` is required for private endpoint subnets.**
  The field name changed in azurerm 3.x and again in 4.x — check the provider changelog.
- **Inline NSG rules vs separate resource.** This module uses `azurerm_network_security_rule`
  (separate) not inline rules inside `azurerm_network_security_group`. Mixing the two causes
  Terraform to fight itself on every plan. Pick one approach and never mix.
- **Subnet delegation.** Some Azure services (App Service Environment, Azure NetApp Files) require
  a dedicated delegated subnet. The delegation block is optional per subnet.
- **DNS servers.** When using Azure Private DNS Resolver in a hub VNet, point DNS servers to the
  inbound resolver endpoint IP. Failing to do this means private DNS zones resolve only via
  Azure's backbone, not through your custom resolver chain.
