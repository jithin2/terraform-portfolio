locals {
  prefix = join(var.separator, [var.environment, var.region_abbreviation, var.application])
  name   = join(var.separator, [local.prefix, var.resource_type])
  slug   = replace(local.name, var.separator, "")

  labels = {
    environment = var.environment
    region      = var.region_abbreviation
    application = var.application
    managed_by  = "terraform"
  }
}
