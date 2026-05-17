locals {
  node_sa_email = var.create_node_sa ? google_service_account.node_sa[0].email : var.node_service_account_email
}

resource "google_service_account" "node_sa" {
  count = var.create_node_sa ? 1 : 0

  account_id   = "${var.cluster_name}-node"
  display_name = "GKE node SA for ${var.cluster_name}"
  project      = var.project_id
}

resource "google_container_cluster" "this" {
  name     = var.cluster_name
  project  = var.project_id
  location = var.location

  network    = var.network
  subnetwork = var.subnetwork

  # Create the cluster with one bootstrapping node then delete the default pool.
  # All real pools are managed as separate google_container_node_pool resources,
  # giving them independent lifecycle (machine type, taints, autoscaling).
  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  private_cluster_config {
    enable_private_nodes    = var.private_cluster_config.enable_private_nodes
    enable_private_endpoint = var.private_cluster_config.enable_private_endpoint
    master_ipv4_cidr_block  = var.master_cidr
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  release_channel {
    channel = var.release_channel
  }

  min_master_version = var.min_master_version

  master_auth {
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  logging_service    = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  enable_legacy_abac = false

  resource_labels = var.labels

  lifecycle {
    ignore_changes = [
      # GKE upgrades the master within the release channel automatically.
      # Tracking this causes perpetual plan drift after each channel upgrade.
      min_master_version,
    ]
  }
}

resource "google_container_node_pool" "pools" {
  for_each = var.node_pools

  name     = each.key
  project  = var.project_id
  location = var.location
  cluster  = google_container_cluster.this.name

  initial_node_count = each.value.initial_node_count

  autoscaling {
    min_node_count = each.value.min_node_count
    max_node_count = each.value.max_node_count
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type    = each.value.machine_type
    disk_size_gb    = each.value.disk_size_gb
    disk_type       = each.value.disk_type
    preemptible     = each.value.preemptible
    spot            = each.value.spot
    service_account = local.node_sa_email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    # GKE_METADATA is required for Workload Identity. Without it pods fall back
    # to the node SA credentials, silently bypassing the WI binding.
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    dynamic "taint" {
      for_each = each.value.node_taints
      content {
        key    = taint.value.key
        value  = taint.value.value
        effect = taint.value.effect
      }
    }

    labels = each.value.node_labels
  }

  lifecycle {
    # GKE sets initial_node_count to the actual autoscaled count after scale events.
    # Ignoring it prevents Terraform from resetting the pool on every plan.
    ignore_changes = [initial_node_count]
  }
}
