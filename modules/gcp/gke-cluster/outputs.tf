# TODO(Step 3): Implement outputs.
#
# output "cluster_id" {
#   description = "GKE cluster resource ID (projects/PROJECT/locations/LOCATION/clusters/NAME)."
# }
# output "cluster_name" {
#   description = "Cluster name. Used when constructing Workload Identity pool member strings."
# }
# output "cluster_endpoint" {
#   description = "IP address of the master API server. Sensitive — store securely."
#   sensitive   = true
# }
# output "cluster_ca_certificate" {
#   description = "Base64-encoded public certificate for the cluster CA. Sensitive."
#   sensitive   = true
# }
# output "workload_identity_pool" {
#   description = "Workload Identity pool name: PROJECT_ID.svc.id.goog. Used in IAM binding member strings."
# }
# output "node_service_account_email" {
#   description = "Email of the node service account. Assign GCR/logging/monitoring roles to this SA."
# }
# output "location" {
#   description = "Cluster location (region or zone)."
# }
# output "master_version" {
#   description = "Current master version. Useful for tracking actual vs requested version."
# }
