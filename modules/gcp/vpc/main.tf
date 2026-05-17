resource "google_compute_network" "this" {
  name                    = var.network_name
  project                 = var.project_id
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
}

resource "google_compute_subnetwork" "this" {
  for_each = var.subnets

  name                     = each.key
  project                  = var.project_id
  region                   = each.value.region
  network                  = google_compute_network.this.self_link
  ip_cidr_range            = each.value.ip_cidr_range
  private_ip_google_access = each.value.private_ip_google_access

  dynamic "secondary_ip_range" {
    for_each = each.value.secondary_ip_ranges
    content {
      range_name    = secondary_ip_range.value.range_name
      ip_cidr_range = secondary_ip_range.value.ip_cidr_range
    }
  }
}

resource "google_compute_router" "nat" {
  count = var.create_nat ? 1 : 0

  name    = "${var.network_name}-router"
  project = var.project_id
  region  = var.nat_router_region
  network = google_compute_network.this.self_link
}

resource "google_compute_router_nat" "this" {
  count = var.create_nat ? 1 : 0

  name                               = "${var.network_name}-nat"
  project                            = var.project_id
  region                             = var.nat_router_region
  router                             = google_compute_router.nat[0].name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = var.nat_log_filter
  }
}
