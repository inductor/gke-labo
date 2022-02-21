provider "google" {
  project     = "the-other-243703"
  region      = "asia-northeast1"
}

resource "google_service_account" "default" {
  account_id   = "gke-sa"
  display_name = "Service Account"
}

resource "google_container_cluster" "primary" {
  name     = "primary"
  location = "asia-northeast1"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  networking_mode = "VPC_NATIVE"
  ip_allocation_policy {

  }
  master_authorized_networks_config {
    cidr_blocks {
      cidr_block = "111.237.107.75/32"
      display_name = "Home"
    }
  }
  network_policy {
    # Enabling NetworkPolicy for clusters with DatapathProvider=ADVANCED_DATAPATH is not allowed (yields error)
    enabled  = false
    # CALICO provider overrides datapath_provider setting, leaving Dataplane v2 disabled
    provider = "PROVIDER_UNSPECIFIED"
  }
  # This is where Dataplane V2 is enabled.
  datapath_provider = "ADVANCED_DATAPATH"
  release_channel {
    channel = "RAPID"
  }
  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = false
    master_ipv4_cidr_block = "172.16.0.0/28"
    master_global_access_config {
      enabled = true
    }
  }
}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "preemtible_nodes"
  location   = "asia-northeast1"
  cluster    = google_container_cluster.primary.name
  node_count = 3

  node_config {
    preemptible  = true
    machine_type = "e2-standard-4"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}
