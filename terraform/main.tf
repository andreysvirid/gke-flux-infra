terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "~> 1.5"
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
# TLS ключі для Flux (можуть знадобитись для SSH, якщо потрібно)
# =====================
resource "tls_private_key" "flux" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# =====================
# GitHub репозиторій для Flux
# =====================
resource "github_repository" "flux_repo" {
  name        = "gke-flux-gitops"
  description = "GitOps repo for Flux-managed cluster"
  visibility  = "private"
}

#resource "github_repository_deploy_key" "flux_key" {
#  repository = github_repository.flux_repo.name
#  title      = "flux-deploy-key"
#  key        = tls_private_key.flux.public_key_openssh
#  read_only  = false
#}

# =====================
# Flux Provider (HTTPS + токен)
# =====================
provider "flux" {
  kubernetes = {
    host                   = google_container_cluster.this.endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(
      google_container_cluster.this.master_auth[0].cluster_ca_certificate
    )
  }

  git = {
    url          = github_repository.flux_repo.http_clone_url  # HTTPS URL
    branch       = "main"
    author_name  = "flux-bot"
    author_email = "flux-bot@example.com"
    username     = var.GITHUB_OWNER
    password     = var.GITHUB_TOKEN
  }
}

# =====================
# Примітка:
# HelmRelease створюється **у Git**, наприклад:
# charts/kbot/kbot-helmrelease.yaml
# Flux автоматично його застосує у кластері
# =====================