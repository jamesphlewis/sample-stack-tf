# main.tf

variable "gke_username" {
  default     = ""
  description = "gke username"
}

variable "gke_password" {
  default     = ""
  description = "gke password"
}

# Provisioning a "google_container_cluster" resource named "primary"
resource "google_container_cluster" "primary" {
  # These variables gets pulled from our variables.tf file
  name     = "${var.project_id}-gke"
  location = var.zone

  # Discard the initial node pool, because we will create our own
  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    username = var.gke_username
    password = var.gke_password

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

# Provisioning a "google_container_node_pool" resource named "primary_nodes"
# We do this separately so we can have finer control over our node pool
resource "google_container_node_pool" "primary_nodes" {
  name       = "${google_container_cluster.primary.name}-node-pool"
  location   = var.zone

  # The cluster for this node pool is the cluster we created above
  cluster    = google_container_cluster.primary.name
  # And start this cluster with two nodes
  node_count = 2

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    # We start with some tiny, preemptible instances for cost purposes
    preemptible  = true
    machine_type = "e2-micro"
  }
}

# Finally, output our GKE cluster name (not necessary but nice to see)
output "gke_cluster_name" {
  value = google_container_cluster.primary.name
}
