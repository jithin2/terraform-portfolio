variable "project_id" {
  description = "GCP project ID for all resources."
  type        = string
}

variable "region" {
  description = "GCP region for all resources."
  type        = string
  default     = "us-east1"
}

variable "region_abbreviation" {
  description = "Short region code for the naming module."
  type        = string
  default     = "ue1"
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
