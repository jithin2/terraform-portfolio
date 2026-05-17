output "network_id" {
  description = "VPC network resource ID."
  value       = google_compute_network.this.id
}

output "network_name" {
  description = "VPC network name."
  value       = google_compute_network.this.name
}

output "network_self_link" {
  description = "VPC network self_link. Pass to the GKE cluster module as the network input."
  value       = google_compute_network.this.self_link
}

output "subnet_ids" {
  description = "Map of subnet name to subnet resource ID."
  value       = { for k, v in google_compute_subnetwork.this : k => v.id }
}

output "subnet_self_links" {
  description = "Map of subnet name to subnet self_link. Pass values to the GKE cluster module as the subnetwork input."
  value       = { for k, v in google_compute_subnetwork.this : k => v.self_link }
}

output "subnet_secondary_ranges" {
  description = "Map of subnet name to list of secondary range objects. Pass range_name values to gke-cluster as pods_secondary_range_name and services_secondary_range_name."
  value       = { for k, v in google_compute_subnetwork.this : k => v.secondary_ip_range }
}

output "nat_router_id" {
  description = "Cloud Router resource ID. null when create_nat = false."
  value       = var.create_nat ? google_compute_router.nat[0].id : null
}
