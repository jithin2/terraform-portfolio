# TODO(Step 3): Implement GCP VPC resources.
#
# Resources:
#
#   google_compute_network "this"
#     · auto_create_subnetworks = false (always — custom mode VPC)
#     · routing_mode = var.routing_mode ("REGIONAL" default, "GLOBAL" for multi-region routing)
#
#   google_compute_subnetwork (for_each over var.subnets)
#     · ip_cidr_range from subnet config
#     · region from subnet config (each subnet can be in a different region)
#     · private_ip_google_access = true (recommended — allows nodes to reach Google APIs
#       without a public IP or NAT, required for GKE private clusters)
#     · secondary_ip_range blocks for pod and services ranges:
#         secondary_ip_range {
#           range_name    = "pods"
#           ip_cidr_range = subnet.pods_cidr
#         }
#         secondary_ip_range {
#           range_name    = "services"
#           ip_cidr_range = subnet.services_cidr
#         }
#       GKE references these by range_name, not by CIDR — the names must match
#       what the GKE cluster module passes as pods_secondary_range_name.
#
#   google_compute_router "nat_router" (count = var.create_nat ? 1 : 0)
#     · Required by Cloud NAT — a router is the parent resource.
#     · region = var.nat_router_region
#
#   google_compute_router_nat "nat" (count = var.create_nat ? 1 : 0)
#     · nat_ip_allocate_option = "AUTO_ONLY" (Google-managed IPs, simplest)
#       or "MANUAL_ONLY" with static IPs (for allowlisting outbound IPs)
#     · source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
#       or "LIST_OF_SUBNETWORKS" for subnet-specific NAT
#     · log_config: enable = true for audit/debug — set filter = "ERRORS_ONLY" in prod
#
# Key design decisions:
#   - Secondary ranges are part of the subnetwork resource, not separate.
#     GKE looks up ranges by name; keeping names consistent with what the GKE module
#     expects ("pods", "services") avoids a common misconfiguration.
#   - Cloud NAT is optional because not all environments need outbound internet access.
#     Private clusters with Private Google Access don't need NAT for Google APIs.
#   - VPC firewall rules are intentionally NOT created in this module — they belong
#     in the consuming module or a dedicated firewall module to avoid resource conflicts
#     with GKE-managed rules.
