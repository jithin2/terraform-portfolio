variable "project_id" {
  description = "GCP project ID where the cluster is deployed."
  type        = string
}

variable "location" {
  description = "Cluster location. Use a region (e.g., us-east1) for a regional cluster with nodes spread across 3 zones. Use a zone for single-zone — not recommended for production."
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster."
  type        = string
}

variable "network" {
  description = "VPC network self_link or name. Prefer self_link from the VPC module output to ensure correct cross-project references."
  type        = string
}

variable "subnetwork" {
  description = "Subnetwork self_link or name for node IPs. Prefer self_link from the VPC module output."
  type        = string
}

variable "pods_secondary_range_name" {
  description = "Name of the secondary IP range on the subnet reserved for pod IPs. Must exactly match the range_name defined in the VPC module — GKE looks this up by name."
  type        = string
}

variable "services_secondary_range_name" {
  description = "Name of the secondary IP range on the subnet reserved for service IPs. Must exactly match the range_name defined in the VPC module."
  type        = string
}

variable "master_cidr" {
  description = "CIDR for the GKE master network. Must be exactly /28 — GKE rejects all other prefix lengths. Must not overlap with node, pod, services, or any peered VPC ranges."
  type        = string

  validation {
    condition     = can(regex("/28$", var.master_cidr))
    error_message = "master_cidr must be a /28 prefix. GKE rejects any other prefix length."
  }
}

variable "private_cluster_config" {
  description = "Private cluster settings. Private nodes have no public IPs; private endpoint removes the public master endpoint entirely."
  type = object({
    enable_private_nodes    = optional(bool, true)
    enable_private_endpoint = optional(bool, false)
  })
  default = {}
}

variable "master_authorized_networks" {
  description = "CIDRs allowed to reach the master API server. An empty list with enable_private_endpoint = false means the master is reachable from anywhere — restrict this in production."
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = []
}

variable "release_channel" {
  description = "GKE release channel. REGULAR balances stability and recency. RAPID gets new features faster. STABLE lags further behind."
  type        = string
  default     = "REGULAR"

  validation {
    condition     = contains(["RAPID", "REGULAR", "STABLE", "UNSPECIFIED"], var.release_channel)
    error_message = "release_channel must be RAPID, REGULAR, STABLE, or UNSPECIFIED."
  }
}

variable "min_master_version" {
  description = "Minimum master version. null = channel default. Set only to prevent the channel from using a version with a known issue."
  type        = string
  default     = null
}

variable "node_pools" {
  description = "Map of node pool configurations. Key becomes the pool name."
  type = map(object({
    machine_type       = string
    disk_size_gb       = optional(number, 100)
    disk_type          = optional(string, "pd-ssd")
    min_node_count     = number
    max_node_count     = number
    initial_node_count = optional(number, 1)
    preemptible        = optional(bool, false)
    spot               = optional(bool, false)
    node_taints = optional(list(object({
      key    = string
      value  = string
      effect = string
    })), [])
    node_labels = optional(map(string), {})
  }))
}

variable "create_node_sa" {
  description = "Create a dedicated minimal service account for GKE nodes. Strongly recommended — the default Compute SA has project-wide permissions that violate least-privilege."
  type        = bool
  default     = true
}

variable "node_service_account_email" {
  description = "Email of an existing service account to use for nodes. Required when create_node_sa = false."
  type        = string
  default     = null
}

variable "labels" {
  description = "Resource labels applied to cluster and node pool resources."
  type        = map(string)
  default     = {}
}
