output "azure_cluster_name" {
  description = "AKS cluster name — prod-eus-demo-aks pattern."
  value       = module.azure_aks.cluster_name
}

output "gcp_cluster_name" {
  description = "GKE cluster name — prod-ue1-demo-gke pattern."
  value       = module.gcp_gke.cluster_name
}

output "azure_oidc_issuer_url" {
  description = "AKS OIDC issuer URL for Workload Identity federation."
  value       = module.azure_aks.oidc_issuer_url
}

output "gcp_workload_identity_pool" {
  description = "GKE Workload Identity pool for IAM binding member strings."
  value       = module.gcp_gke.workload_identity_pool
}
