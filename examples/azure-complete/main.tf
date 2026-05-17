locals {
  environment = var.environment
  location    = var.location
}

module "naming_vnet" {
  source              = "../../modules/shared/naming"
  environment         = local.environment
  region_abbreviation = var.region_abbreviation
  application         = var.application
  resource_type       = "vnet"
}

module "naming_aks" {
  source              = "../../modules/shared/naming"
  environment         = local.environment
  region_abbreviation = var.region_abbreviation
  application         = var.application
  resource_type       = "aks"
}

module "naming_kv" {
  source              = "../../modules/shared/naming"
  environment         = local.environment
  region_abbreviation = var.region_abbreviation
  application         = var.application
  resource_type       = "kv"
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = local.location
  tags     = module.naming_vnet.labels
}

module "vnet" {
  source = "../../modules/azure/vnet"

  resource_group_name = azurerm_resource_group.main.name
  location            = local.location
  vnet_name           = module.naming_vnet.name
  address_space       = ["10.0.0.0/16"]
  tags                = module.naming_vnet.labels

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
}

resource "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.main.name
  tags                = module.naming_kv.labels
}

resource "azurerm_private_dns_zone_virtual_network_link" "kv" {
  name                  = "kv-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.kv.name
  virtual_network_id    = module.vnet.vnet_id
}

module "key_vault" {
  source = "../../modules/azure/key-vault"

  resource_group_name        = azurerm_resource_group.main.name
  location                   = local.location
  name                       = module.naming_kv.slug
  enable_private_endpoint    = true
  private_endpoint_subnet_id = module.vnet.subnet_ids["pep"]
  private_dns_zone_id        = azurerm_private_dns_zone.kv.id
  tags                       = module.naming_kv.labels

  depends_on = [azurerm_private_dns_zone_virtual_network_link.kv]
}

resource "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.${local.location}.azmk8s.io"
  resource_group_name = azurerm_resource_group.main.name
  tags                = module.naming_aks.labels
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks" {
  name                  = "aks-dns-link"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = module.vnet.vnet_id
}

module "aks" {
  source = "../../modules/azure/aks-cluster"

  resource_group_name     = azurerm_resource_group.main.name
  location                = local.location
  cluster_name            = module.naming_aks.name
  private_cluster_enabled = true
  private_dns_zone_id     = azurerm_private_dns_zone.aks.id
  tags                    = module.naming_aks.labels

  default_node_pool = {
    name                 = "system"
    vm_size              = "Standard_D4ds_v5"
    min_count            = 2
    max_count            = 4
    vnet_subnet_id       = module.vnet.subnet_ids["aks-system"]
    only_critical_addons = true
  }

  user_node_pools = {
    "app" = {
      vm_size        = "Standard_D8ds_v5"
      min_count      = 2
      max_count      = 10
      vnet_subnet_id = module.vnet.subnet_ids["aks-user"]
      node_taints    = ["workload=app:NoSchedule"]
    }
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.aks]
}

# Grant the AKS kubelet identity read access to Key Vault secrets.
# Role assignments are created by the caller, not inside the modules.
resource "azurerm_role_assignment" "aks_kv_secrets_user" {
  scope                = module.key_vault.vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = module.aks.kubelet_identity[0].object_id
}
