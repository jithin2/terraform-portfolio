# Each cloud gets its own naming module call because region abbreviations differ.
# The structure is identical — env-region-app-type — but eus vs ue1 reflects
# the fact that cloud regions have different naming conventions.

module "azure_naming_vnet" {
  source              = "../../modules/shared/naming"
  environment         = var.environment
  region_abbreviation = var.azure_region_abbreviation
  application         = var.application
  resource_type       = "vnet"
}

module "azure_naming_aks" {
  source              = "../../modules/shared/naming"
  environment         = var.environment
  region_abbreviation = var.azure_region_abbreviation
  application         = var.application
  resource_type       = "aks"
}

module "gcp_naming_vpc" {
  source              = "../../modules/shared/naming"
  environment         = var.environment
  region_abbreviation = var.gcp_region_abbreviation
  application         = var.application
  resource_type       = "vpc"
}

module "gcp_naming_gke" {
  source              = "../../modules/shared/naming"
  environment         = var.environment
  region_abbreviation = var.gcp_region_abbreviation
  application         = var.application
  resource_type       = "gke"
}

# Azure stack
resource "azurerm_resource_group" "main" {
  name     = var.azure_resource_group_name
  location = var.azure_location
  tags     = module.azure_naming_vnet.labels
}

module "azure_vnet" {
  source = "../../modules/azure/vnet"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.azure_location
  vnet_name           = module.azure_naming_vnet.name
  address_space       = ["10.0.0.0/16"]
  tags                = module.azure_naming_vnet.labels

  subnets = {
    "aks-system" = { address_prefix = "10.0.0.0/22" }
    "aks-user"   = { address_prefix = "10.0.4.0/22" }
  }
}

module "azure_aks" {
  source = "../../modules/azure/aks-cluster"

  resource_group_name = azurerm_resource_group.main.name
  location            = var.azure_location
  cluster_name        = module.azure_naming_aks.name
  tags                = module.azure_naming_aks.labels

  default_node_pool = {
    name           = "system"
    vm_size        = "Standard_D4ds_v5"
    min_count      = 2
    max_count      = 4
    vnet_subnet_id = module.azure_vnet.subnet_ids["aks-system"]
  }
}

# GCP stack
module "gcp_vpc" {
  source = "../../modules/gcp/vpc"

  project_id   = var.gcp_project_id
  network_name = module.gcp_naming_vpc.name
  labels       = module.gcp_naming_vpc.labels

  subnets = {
    "gke-nodes" = {
      ip_cidr_range = "10.10.0.0/22"
      region        = var.gcp_region
      secondary_ip_ranges = [
        { range_name = "pods",     ip_cidr_range = "10.11.0.0/16" },
        { range_name = "services", ip_cidr_range = "10.12.0.0/20" }
      ]
    }
  }
}

module "gcp_gke" {
  source = "../../modules/gcp/gke-cluster"

  project_id   = var.gcp_project_id
  location     = var.gcp_region
  cluster_name = module.gcp_naming_gke.name
  labels       = module.gcp_naming_gke.labels

  network    = module.gcp_vpc.network_self_link
  subnetwork = module.gcp_vpc.subnet_self_links["gke-nodes"]

  pods_secondary_range_name     = "pods"
  services_secondary_range_name = "services"
  master_cidr                   = "172.16.0.0/28"

  node_pools = {
    "app" = {
      machine_type   = "n2-standard-8"
      min_node_count = 2
      max_node_count = 10
    }
  }
}
