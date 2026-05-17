locals {
  # Flatten iam_bindings list into a map with a stable key for for_each.
  # Using count would shift state addresses when a binding in the middle is removed.
  iam_bindings_map = {
    for b in var.iam_bindings :
    "${b.secret_key}--${b.role}--${b.member}" => b
  }
}

resource "google_secret_manager_secret" "this" {
  for_each = var.secrets

  project   = var.project_id
  secret_id = each.key
  labels    = merge(var.labels, lookup(each.value, "labels", {}))

  replication {
    dynamic "auto" {
      for_each = each.value.replication_type == "automatic" ? [1] : []
      content {}
    }

    dynamic "user_managed" {
      for_each = each.value.replication_type == "user_managed" ? [1] : []
      content {
        dynamic "replicas" {
          for_each = each.value.replica_locations
          content {
            location = replicas.value
          }
        }
      }
    }
  }
}

resource "google_secret_manager_secret_version" "this" {
  for_each = { for k, v in var.secrets : k => v if v.initial_value != null }

  secret      = google_secret_manager_secret.this[each.key].id
  secret_data = each.value.initial_value
}

# iam_member (additive) not iam_binding (authoritative) — avoids clobbering
# bindings managed outside this module (e.g., GKE Workload Identity setup).
resource "google_secret_manager_secret_iam_member" "this" {
  for_each = local.iam_bindings_map

  project   = var.project_id
  secret_id = google_secret_manager_secret.this[each.value.secret_key].secret_id
  role      = each.value.role
  member    = each.value.member
}
