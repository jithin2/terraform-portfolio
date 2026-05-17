# TODO(Step 4): Wire vpc + gke-cluster + secret-manager end-to-end.
#
# This example demonstrates:
#   1. Shared naming module consumed by all three GCP modules
#   2. VPC with secondary ranges sized for GKE pods and services
#   3. GKE private cluster referencing the VPC's subnet and secondary range names
#   4. Secret Manager secrets with IAM bindings to the GKE node service account
#   5. Workload Identity binding: K8s SA → GCP SA (shown as commented resource)
#
# Module call order:
#   naming → vpc → gke-cluster → secret-manager → iam bindings
#
# Provider block: google provider with project and region.
# Backend: local for example; note that production should use gcs backend.
