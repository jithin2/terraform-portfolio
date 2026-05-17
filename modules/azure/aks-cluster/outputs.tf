output "cluster_id" {
  description = "Azure resource ID of the AKS cluster. Use as scope for role assignments targeting the cluster itself."
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "Name of the AKS cluster."
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_fqdn" {
  description = "Public FQDN of the API server. Empty string for fully private clusters."
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "private_fqdn" {
  description = "Private FQDN of the API server. Populated only when private_cluster_enabled = true."
  value       = azurerm_kubernetes_cluster.this.private_fqdn
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for this cluster. Pass to azurerm_federated_identity_credential.oidc_issuer_url when setting up Workload Identity for a pod."
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "kubelet_identity" {
  description = "Kubelet managed identity object. Pass object_id to Key Vault Secrets User and AcrPull role assignments. Pass client_id to the azure.workload.identity/client-id annotation on K8s ServiceAccounts."
  value       = azurerm_kubernetes_cluster.this.kubelet_identity
}

output "cluster_identity" {
  description = "Control-plane managed identity. Assign Network Contributor (subnet) and Private DNS Zone Contributor (DNS zone) to this identity — not to the kubelet identity."
  value       = azurerm_kubernetes_cluster.this.identity
}

output "node_resource_group" {
  description = "Name of the MC_ node resource group. Needed when creating role assignments on node-level resources such as disks or public IPs."
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "node_resource_group_id" {
  description = "Resource ID of the MC_ node resource group."
  value       = azurerm_kubernetes_cluster.this.node_resource_group_id
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the cluster. Sensitive — store in Key Vault or a dedicated secrets manager. Do not write to a shared Terraform backend in plaintext."
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}
