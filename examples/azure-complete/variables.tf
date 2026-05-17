variable "resource_group_name" {
  description = "Name of the resource group to create."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "region_abbreviation" {
  description = "Short region code for the naming module."
  type        = string
  default     = "eus"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"
}

variable "application" {
  description = "Application name for the naming module."
  type        = string
  default     = "demo"
}
