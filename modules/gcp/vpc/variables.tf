variable "project_id" {
  description = "GCP project ID where the VPC is created."
  type        = string
}

variable "network_name" {
  description = "Name of the VPC network."
  type        = string
}

variable "routing_mode" {
  description = "VPC routing mode. REGIONAL routes are advertised only within the subnet's region. GLOBAL routes are advertised to all regions — use for multi-region clusters sharing a single VPC."
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "GLOBAL"], var.routing_mode)
    error_message = "routing_mode must be REGIONAL or GLOBAL."
  }
}

variable "subnets" {
  description = "Map of subnet configurations. Key becomes the subnet name."
  type = map(object({
    ip_cidr_range            = string
    region                   = string
    private_ip_google_access = optional(bool, true)
    secondary_ip_ranges = optional(list(object({
      range_name    = string
      ip_cidr_range = string
    })), [])
  }))
}

variable "create_nat" {
  description = "Create a Cloud NAT gateway for outbound internet access. Private GKE nodes accessing only Google APIs via Private Google Access do not need NAT."
  type        = bool
  default     = false
}

variable "nat_router_region" {
  description = "Region for the Cloud Router and NAT gateway. Required when create_nat = true."
  type        = string
  default     = null
}

variable "nat_log_filter" {
  description = "NAT log filter level. ERRORS_ONLY is sufficient for production alerting."
  type        = string
  default     = "ERRORS_ONLY"

  validation {
    condition     = contains(["ERRORS_ONLY", "TRANSLATIONS_ONLY", "ALL"], var.nat_log_filter)
    error_message = "nat_log_filter must be ERRORS_ONLY, TRANSLATIONS_ONLY, or ALL."
  }
}

variable "labels" {
  description = "Labels applied to network resources."
  type        = map(string)
  default     = {}
}
