variable "resource_group_name" {
  description = "Name of the Azure resource group where the AKS cluster is deployed."
  type        = string
}

variable "location" {
  description = "Azure region for the cluster (e.g., eastus, westeurope)."
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster. Also used as the dns_prefix — must be unique within the resource group."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to pin. null = AKS-recommended latest. Pin explicitly for production clusters to control when upgrades happen."
  type        = string
  default     = null
}

variable "sku_tier" {
  description = "AKS cluster SLA tier. Standard and Premium include the 99.95% API server uptime SLA. Free has no SLA."
  type        = string
  default     = "Standard"

  validation {
    condition     = contains(["Free", "Standard", "Premium"], var.sku_tier)
    error_message = "sku_tier must be Free, Standard, or Premium."
  }
}

variable "node_resource_group" {
  description = "Name for the auto-generated MC_ node resource group. When null AKS uses MC_{rg}_{cluster}_{region}. Set explicitly to satisfy org naming policies."
  type        = string
  default     = null
}

variable "default_node_pool" {
  description = "System node pool configuration. This pool cannot be deleted; changing vm_size forces cluster recreation."
  type = object({
    name                 = string
    vm_size              = string
    min_count            = number
    max_count            = number
    vnet_subnet_id       = string
    os_disk_type         = optional(string, "Ephemeral")
    os_disk_size_gb      = optional(number, null)
    only_critical_addons = optional(bool, true)
  })
}

variable "user_node_pools" {
  description = "Map of user node pool configurations. Key becomes the pool name (max 12 alphanumeric characters — AKS limit)."
  type = map(object({
    vm_size        = string
    min_count      = number
    max_count      = number
    vnet_subnet_id = string
    os_disk_type   = optional(string, "Ephemeral")
    node_taints    = optional(list(string), [])
    node_labels    = optional(map(string), {})
    max_surge      = optional(string, "33%")
  }))
  default = {}
}

variable "identity_type" {
  description = "Control-plane managed identity type. UserAssigned is preferred for production — you pre-create the identity, assign roles before cluster creation, and avoid timing issues with SystemAssigned role propagation."
  type        = string
  default     = "SystemAssigned"

  validation {
    condition     = contains(["SystemAssigned", "UserAssigned"], var.identity_type)
    error_message = "identity_type must be SystemAssigned or UserAssigned."
  }
}

variable "control_plane_identity_id" {
  description = "Resource ID of the user-assigned managed identity for the AKS control plane. Required when identity_type = UserAssigned. Assign Network Contributor on the subnet and Private DNS Zone Contributor on the DNS zone to this identity before creating the cluster."
  type        = string
  default     = null
}

variable "kubelet_identity" {
  description = "User-assigned managed identity for the kubelet (workload pods). Required when identity_type = UserAssigned. This is the identity that pods exchange for short-lived tokens via Workload Identity — it is separate from the control-plane identity."
  type = object({
    user_assigned_identity_id = string
    client_id                 = string
    object_id                 = string
  })
  default = null
}

variable "oidc_issuer_enabled" {
  description = "Enable the OIDC issuer. Required for Workload Identity. Enabling on an existing cluster causes a brief API server restart."
  type        = bool
  default     = true
}

variable "workload_identity_enabled" {
  description = "Enable the Workload Identity mutating webhook. Requires oidc_issuer_enabled = true — the two must be enabled together."
  type        = bool
  default     = true
}

variable "private_cluster_enabled" {
  description = "Deploy the API server behind a Private Link endpoint inside the VNet. kubectl access requires a jump host, VPN, or ExpressRoute."
  type        = bool
  default     = false
}

variable "private_cluster_public_fqdn_enabled" {
  description = "Expose a public FQDN even when the cluster is private. Leave false for fully private clusters — only set true for the hybrid pattern where private nodes need a public DNS entry for the API server."
  type        = bool
  default     = false
}

variable "private_dns_zone_id" {
  description = "Resource ID of the private DNS zone for the API server endpoint. Required when private_cluster_enabled = true. Pass 'System' for Azure-managed zone (created in the MC_ RG), or pass an actual zone ID for BYO zone (recommended for hub/spoke — link the zone to the hub VNet)."
  type        = string
  default     = null
}

variable "network_profile" {
  description = "AKS network configuration. Azure CNI default for enterprise — predictable IP allocation and direct pod routing without an overlay."
  type = object({
    network_plugin    = optional(string, "azure")
    network_policy    = optional(string, "calico")
    service_cidr      = optional(string, "172.16.0.0/16")
    dns_service_ip    = optional(string, "172.16.0.10")
    load_balancer_sku = optional(string, "standard")
    outbound_type     = optional(string, "loadBalancer")
  })
  default = {}

  validation {
    condition     = contains(["azure", "kubenet", "none"], var.network_profile.network_plugin)
    error_message = "network_plugin must be azure, kubenet, or none."
  }

  validation {
    condition     = contains(["loadBalancer", "userDefinedRouting", "managedNATGateway", "userAssignedNATGateway"], var.network_profile.outbound_type)
    error_message = "outbound_type must be one of: loadBalancer, userDefinedRouting, managedNATGateway, userAssignedNATGateway."
  }
}

variable "azure_rbac_enabled" {
  description = "Use Azure RBAC for Kubernetes RBAC. Allows standard Azure role assignments to control kubectl access rather than K8s ClusterRoleBindings."
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "Object IDs of Azure AD groups that receive cluster-admin access. Optional — teams can use fine-grained Azure RBAC role assignments instead."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to all resources in this module."
  type        = map(string)
  default     = {}
}
