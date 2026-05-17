variable "environment" {
  description = "Deployment environment — shared across both clouds."
  type        = string
  default     = "dev"
}

variable "application" {
  description = "Application name — shared across both clouds."
  type        = string
  default     = "demo"
}

# Azure
variable "azure_resource_group_name" {
  description = "Name of the Azure resource group to create."
  type        = string
}

variable "azure_location" {
  description = "Azure region."
  type        = string
  default     = "eastus"
}

variable "azure_region_abbreviation" {
  description = "Short Azure region code for the naming module."
  type        = string
  default     = "eus"
}

# GCP
variable "gcp_project_id" {
  description = "GCP project ID."
  type        = string
}

variable "gcp_region" {
  description = "GCP region."
  type        = string
  default     = "us-east1"
}

variable "gcp_region_abbreviation" {
  description = "Short GCP region code for the naming module."
  type        = string
  default     = "ue1"
}
