module "naming_vpc" {
  source              = "../../modules/shared/naming"
  environment         = var.environment
  region_abbreviation = var.region_abbreviation
  application         = var.application
  resource_type       = "vpc"
}

module "naming_gke" {
  source              = "../../modules/shared/naming"
  environment         = var.environment
  region_abbreviation = var.region_abbreviation
  application         = var.application
  resource_type       = "gke"
}

module "naming_sm" {
  source              = "../../modules/shared/naming"
  environment         = var.environment
  region_abbreviation = var.region_abbreviation
  application         = var.application
  resource_type       = "sm"
}

module "vpc" {
  source = "../../modules/gcp/vpc"

  project_id   = var.project_id
  network_name = module.naming_vpc.name
  labels       = module.naming_vpc.labels

  subnets = {
    "gke-nodes" = {
      ip_cidr_range = "10.0.0.0/22"
      region        = var.region
      secondary_ip_ranges = [
        { range_name = "pods",     ip_cidr_range = "10.1.0.0/16" },
        { range_name = "services", ip_cidr_range = "10.2.0.0/20" }
      ]
    }
  }

  create_nat        = true
  nat_router_region = var.region
}

module "gke" {
  source = "../../modules/gcp/gke-cluster"

  project_id   = var.project_id
  location     = var.region
  cluster_name = module.naming_gke.name
  labels       = module.naming_gke.labels

  network    = module.vpc.network_self_link
  subnetwork = module.vpc.subnet_self_links["gke-nodes"]

  pods_secondary_range_name     = "pods"
  services_secondary_range_name = "services"
  master_cidr                   = "172.16.0.0/28"

  private_cluster_config = {
    enable_private_nodes    = true
    enable_private_endpoint = false
  }

  node_pools = {
    "app" = {
      machine_type   = "n2-standard-8"
      min_node_count = 2
      max_node_count = 10
    }
  }
}

module "secrets" {
  source = "../../modules/gcp/secret-manager"

  project_id = var.project_id
  labels     = module.naming_sm.labels

  secrets = {
    "db-password" = { replication_type = "automatic" }
    "api-key"     = { replication_type = "automatic" }
  }

  iam_bindings = [
    {
      secret_key = "db-password"
      role       = "roles/secretmanager.secretAccessor"
      member     = "serviceAccount:${module.gke.node_service_account_email}"
    }
  ]
}
