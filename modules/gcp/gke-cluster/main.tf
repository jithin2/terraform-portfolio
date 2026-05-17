# TODO(Step 3): Implement GKE cluster resources.
#
# Resources:
#
#   google_container_cluster "this"
#     · remove_default_node_pool = true, initial_node_count = 1
#       Standard pattern: create the cluster with a minimal default pool, then immediately
#       delete it via this flag. All real pools are managed as separate node pool resources.
#       Reason: the default pool is tightly coupled to the cluster resource and cannot be
#       modified in-place; separate node pool resources support independent lifecycle.
#     · network, subnetwork from var.network and var.subnetwork (self_links recommended)
#     · ip_allocation_policy:
#         cluster_secondary_range_name  = var.pods_secondary_range_name
#         services_secondary_range_name = var.services_secondary_range_name
#       These reference named secondary ranges on the subnet (defined in the VPC module).
#       IP aliases must be enabled (implicit when ip_allocation_policy is set).
#     · private_cluster_config:
#         enable_private_nodes    = true
#         enable_private_endpoint = var.private_cluster_config.enable_private_endpoint
#         master_ipv4_cidr_block  = var.master_cidr  (/28 required, must not overlap any range)
#     · master_authorized_networks_config: list of CIDRs allowed to reach the master.
#       For purely private clusters pass an empty list or internal ranges only.
#     · workload_identity_config:
#         workload_pool = "${var.project_id}.svc.id.goog"
#     · release_channel: RAPID / REGULAR / STABLE — controls auto-upgrade cadence.
#     · logging_service, monitoring_service = "logging.googleapis.com/kubernetes" etc.
#       (or "none" for custom logging stacks — but disable thoughtfully)
#
#   google_container_node_pool "user" (for_each over var.node_pools)
#     · cluster = google_container_cluster.this.name (not .id — avoids dependency cycle)
#     · node_config:
#         service_account = google_service_account.node_sa.email (if create_node_sa)
#         oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
#         workload_metadata_config: mode = "GKE_METADATA" (required for Workload Identity)
#         shielded_instance_config: enabled recommended
#     · management: auto_repair = true, auto_upgrade = true (aligns with release_channel)
#     · autoscaling: min_node_count, max_node_count from pool config
#
#   google_service_account "node_sa" (count = var.create_node_sa ? 1 : 0)
#     · Minimal SA for nodes — no roles by default, scoped by oauth_scopes.
#     · Caller assigns project-level roles (e.g., roles/logging.logWriter,
#       roles/monitoring.metricWriter, roles/storage.objectViewer for GCR).
#
# Key design decisions:
#   - for_each on node_pools map (not count) — stable state addresses.
#   - Workload Identity requires GKE_METADATA mode on nodes. Without it, pods fall back
#     to the node SA, bypassing the identity binding entirely (silent security issue).
#   - master_cidr must be /28 exactly — GKE rejects other prefix lengths.
