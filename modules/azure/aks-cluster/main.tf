resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier
  node_resource_group = var.node_resource_group

  default_node_pool {
    name                         = var.default_node_pool.name
    vm_size                      = var.default_node_pool.vm_size
    auto_scaling_enabled         = true
    min_count                    = var.default_node_pool.min_count
    max_count                    = var.default_node_pool.max_count
    vnet_subnet_id               = var.default_node_pool.vnet_subnet_id
    os_disk_type                 = var.default_node_pool.os_disk_type
    os_disk_size_gb              = var.default_node_pool.os_disk_size_gb
    only_critical_addons_enabled = var.default_node_pool.only_critical_addons
    orchestrator_version         = var.kubernetes_version

    upgrade_settings {
      max_surge = "33%"
    }
  }

  identity {
    type         = var.identity_type
    identity_ids = var.identity_type == "UserAssigned" ? [var.control_plane_identity_id] : null
  }

  # kubelet_identity is the per-pod identity used by Workload Identity.
  # It is distinct from the control-plane identity above.
  # Without this block AKS auto-creates a system-assigned kubelet identity.
  dynamic "kubelet_identity" {
    for_each = var.identity_type == "UserAssigned" ? [1] : []
    content {
      user_assigned_identity_id = var.kubelet_identity.user_assigned_identity_id
      client_id                 = var.kubelet_identity.client_id
      object_id                 = var.kubelet_identity.object_id
    }
  }

  oidc_issuer_enabled       = var.oidc_issuer_enabled
  workload_identity_enabled = var.workload_identity_enabled

  private_cluster_enabled             = var.private_cluster_enabled
  private_cluster_public_fqdn_enabled = var.private_cluster_public_fqdn_enabled
  private_dns_zone_id                 = var.private_cluster_enabled ? var.private_dns_zone_id : null

  network_profile {
    network_plugin    = var.network_profile.network_plugin
    network_policy    = var.network_profile.network_policy
    service_cidr      = var.network_profile.service_cidr
    dns_service_ip    = var.network_profile.dns_service_ip
    load_balancer_sku = var.network_profile.load_balancer_sku
    outbound_type     = var.network_profile.outbound_type
  }

  azure_active_directory_role_based_access_control {
    azure_rbac_enabled     = var.azure_rbac_enabled
    admin_group_object_ids = var.admin_group_object_ids
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [
      # AKS upgrades kubernetes_version and orchestrator_version automatically
      # via maintenance windows and release channels. Tracking them here causes
      # perpetual plan drift as the cluster moves past the pinned version.
      kubernetes_version,
      default_node_pool[0].orchestrator_version,
    ]

    precondition {
      condition     = var.identity_type == "SystemAssigned" || var.control_plane_identity_id != null
      error_message = "control_plane_identity_id must be provided when identity_type is UserAssigned."
    }

    precondition {
      condition     = var.identity_type == "SystemAssigned" || var.kubelet_identity != null
      error_message = "kubelet_identity must be provided when identity_type is UserAssigned."
    }

    precondition {
      condition     = !var.private_cluster_enabled || var.private_dns_zone_id != null
      error_message = "private_dns_zone_id is required when private_cluster_enabled is true. Pass the zone resource ID for BYO zone, or the string 'System' for an Azure-managed zone."
    }
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "user" {
  for_each = var.user_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  mode                  = "User"
  auto_scaling_enabled  = true
  min_count             = each.value.min_count
  max_count             = each.value.max_count
  vnet_subnet_id        = each.value.vnet_subnet_id
  os_disk_type          = each.value.os_disk_type
  node_taints           = each.value.node_taints
  node_labels           = each.value.node_labels
  orchestrator_version  = var.kubernetes_version

  upgrade_settings {
    max_surge = each.value.max_surge
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [orchestrator_version]
  }
}
