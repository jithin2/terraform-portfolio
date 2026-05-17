# TODO: Verify azurerm version range against https://registry.terraform.io/providers/hashicorp/azurerm/latest
# before deploying. The ~> 4.0 constraint allows 4.x releases; pin more tightly if needed.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}
