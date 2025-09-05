# =====================
# HelmRelease можна додати у Git
# Наприклад, у репо: clusters/gke/kbot-helmrelease.yaml
# =====================

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "~> 1.6"
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

data "google_client_config" "default" {}

# =====================
# Flux Provider (HTTPS + токен, гілка develop)
# =====================
provider "flux" {
  kubernetes = {
    host                   = google_container_cluster.this.endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(google_container_cluster.this.master_auth[0].cluster_ca_certificate)
  }

  git = {
    url          = github_repository.flux_repo.http_clone_url  # HTTPS URL
    branch       = "develop"                                   # вказуємо гілку develop
    author_name  = "flux-bot"
    author_email = "flux-bot@example.com"
    username     = var.GITHUB_OWNER
    password     = var.GITHUB_TOKEN
  }
}

# =====================
# GKE Cluster (якщо кластер вже є, цей блок можна коментувати)
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
  name        = "gke-flux-gitops"
  description = "GitOps repo for Flux-managed cluster"
  visibility  = "private"
}

# =====================
# Bootstrap Flux у кластері
# =====================
resource "flux_bootstrap_git" "this" {
  url      = "https://github.com/andreysvirid/gke-flux-infra.git"
  branch   = "develop"  # якщо хочеш явно вказати гілку
  path     = "./clusters"

  author {
    name  = "flux-bot"
    email = "flux-bot@example.com"
  }

  git_auth {
    user  = var.GITHUB_OWNER
    token = var.GITHUB_TOKEN
  }
}

# =====================
# Outputs
# =====================
output "flux_git_url" {
  value = github_repository.flux_repo.http_clone_url
}

output "cluster_name" {
  value = google_container_cluster.this.name
}