# Verify the google provider version range against https://registry.terraform.io/providers/hashicorp/google/latest
# before deploying to any environment.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}
