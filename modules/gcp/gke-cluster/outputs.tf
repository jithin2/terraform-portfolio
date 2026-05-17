output "cluster_id" {
  description = "Full GKE cluster resource ID: projects/PROJECT/locations/LOCATION/clusters/NAME."
  value       = google_container_cluster.this.id
}

output "cluster_name" {
  description = "GKE cluster name. Used when building Workload Identity IAM member strings: serviceAccount:PROJECT_ID.svc.id.goog[NAMESPACE/KSA_NAME]."
  value       = google_container_cluster.this.name
}

output "cluster_endpoint" {
  description = "IP address of the master API server. Sensitive — do not expose in logs or unencrypted state."
  value       = google_container_cluster.this.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64-encoded public certificate for the cluster CA. Used when configuring the Kubernetes Terraform provider or kubectl. Sensitive."
  value       = google_container_cluster.this.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "workload_identity_pool" {
  description = "Workload Identity pool: PROJECT_ID.svc.id.goog. Use as the prefix when constructing IAM binding members for Workload Identity."
  value       = google_container_cluster.this.workload_identity_config[0].workload_pool
}

output "node_service_account_email" {
  description = "Email of the GKE node service account. Assign roles/logging.logWriter, roles/monitoring.metricWriter, and roles/storage.objectViewer (for Container Registry) to this SA from the calling module."
  value       = local.node_sa_email
}

output "location" {
  description = "Cluster location (region or zone)."
  value       = google_container_cluster.this.location
}

output "master_version" {
  description = "Current master Kubernetes version as reported by GKE. Useful to confirm the version after an automatic channel upgrade."
  value       = google_container_cluster.this.master_version
}
