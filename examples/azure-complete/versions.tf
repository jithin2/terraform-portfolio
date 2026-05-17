# TODO(Step 4): Add provider and version constraints.
# TODO: Verify azurerm version range before deploying.

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

# provider "azurerm" {
#   features {
#     key_vault {
#       purge_soft_delete_on_destroy    = false
#       recover_soft_deleted_key_vaults = true
#     }
#   }
# }
