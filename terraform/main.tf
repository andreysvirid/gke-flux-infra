terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.6"
    }
  }

  backend "gcs" {
    bucket = "my-terra-state-bucket"
    prefix = "terraform/state"
  }
}

provider "google" {
  project = var.GOOGLE_PROJECT
  region  = var.GOOGLE_REGION
}

provider "github" {
  token = var.GITHUB_TOKEN
}

# =====================
# GKE Cluster
# =====================
resource "google_container_cluster" "this" {
  name     = "example-cluster"
  location = var.GOOGLE_REGION

  node_config {
    machine_type = "n1-standard-1"
    disk_type    = "pd-standard"
    disk_size_gb = 50
  }

  initial_node_count  = var.GKE_NUM_NODES
  deletion_protection = false
}

# =====================
# GitHub репозиторій для Flux
# =====================
resource "github_repository" "flux_repo" {
  name        = "gke-flux-infra2"
  description = "GitOps repository for Flux-managed GKE cluster"
  visibility  = "private"
  auto_init   = true      # створює default README
}

# =====================
# Outputs
# =====================
output "gke_cluster_name" {
  value = google_container_cluster.this.name
}

output "flux_repo_https_url" {
  value = github_repository.flux_repo.html_url
}