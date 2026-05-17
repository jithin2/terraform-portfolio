# TODO(Step 4): Show naming parity across clouds.
#
# output "azure_cluster_name" { value = module.azure_naming_aks.name }  # prod-eus-demo-aks
# output "gcp_cluster_name"   { value = module.gcp_naming_gke.name }    # prod-ue1-demo-gke
# output "azure_oidc_issuer"  { value = module.aks.oidc_issuer_url }
# output "gcp_wi_pool"        { value = module.gke.workload_identity_pool }
