# TODO: Verify google provider version range against https://registry.terraform.io/providers/hashicorp/google/latest
# before deploying. The ~> 6.0 constraint allows 6.x releases; pin more tightly if needed.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}
