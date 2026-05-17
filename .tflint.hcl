config {
  format              = "compact"
  call_module_type    = "all"
  force               = false
}

# Azure provider ruleset
# TODO: Verify the latest version at https://github.com/terraform-linters/tflint-ruleset-azurerm/releases
plugin "azurerm" {
  enabled = true
  version = "0.27.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}

# GCP provider ruleset
# TODO: Verify the latest version at https://github.com/terraform-linters/tflint-ruleset-google/releases
plugin "google" {
  enabled = true
  version = "0.29.0"
  source  = "github.com/terraform-linters/tflint-ruleset-google"
}

# Core rules — enforce Terraform language best practices
rule "terraform_deprecated_interpolation" { enabled = true }
rule "terraform_deprecated_index"         { enabled = true }
rule "terraform_unused_declarations"      { enabled = true }
rule "terraform_comment_syntax"           { enabled = true }
rule "terraform_documented_outputs"       { enabled = true }
rule "terraform_documented_variables"     { enabled = true }
rule "terraform_typed_variables"          { enabled = true }
rule "terraform_module_pinned_source"     { enabled = true }
rule "terraform_naming_convention"        { enabled = true }
rule "terraform_required_version"         { enabled = true }
rule "terraform_required_providers"       { enabled = true }
