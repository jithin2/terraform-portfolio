# TODO(Step 2): Implement outputs — export everything downstream modules need.
#
# output "cluster_id"   { description = "Azure resource ID of the AKS cluster." }
# output "cluster_name" { description = "Name of the AKS cluster." }
#
# output "cluster_fqdn" {
#   description = "Public FQDN of the API server. Empty string when private_cluster_enabled = true."
# }
# output "private_fqdn" {
#   description = "Private FQDN of the API server. Populated only when private_cluster_enabled = true."
# }
#
# output "oidc_issuer_url" {
#   description = <<-EOT
#     OIDC issuer URL. Required by external systems creating federated credentials
#     (Azure AD app registrations, Workload Identity federation).
#     Downstream usage: azurerm_federated_identity_credential.oidc_issuer_url = module.aks.oidc_issuer_url
#   EOT
# }
#
# output "kubelet_identity" {
#   description = "Object containing client_id, object_id, user_assigned_identity_id of the kubelet managed identity."
# }
#
# output "node_resource_group" {
#   description = "Name of the auto-generated MC_ resource group. Needed for role assignments on node-level resources."
# }
#
# output "kube_config_raw" {
#   description = "Raw kubeconfig. Marked sensitive — store in Key Vault, not in plain state."
#   sensitive   = true
# }
#
# output "cluster_identity" {
#   description = "The control-plane managed identity. Assign roles (Network Contributor, DNS Contributor) to this, not to the kubelet identity."
# }
