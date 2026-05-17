output "gke_cluster_name" {
  description = "Name of the GKE cluster."
  value       = module.gke.cluster_name
}

output "workload_identity_pool" {
  description = "Workload Identity pool: PROJECT_ID.svc.id.goog. Use as prefix in IAM member strings."
  value       = module.gke.workload_identity_pool
}

output "node_service_account_email" {
  description = "GKE node service account email."
  value       = module.gke.node_service_account_email
}

output "secret_resource_paths" {
  description = "Map of secret name to latest version path for application config."
  value       = module.secrets.secret_resource_paths
}
