output "gke_cluster_name" {
  description = "Назва GKE кластера"
  value       = google_container_cluster.this.name
}

output "gke_cluster_endpoint" {
  description = "Endpoint GKE кластера"
  value       = google_container_cluster.this.endpoint
}

output "flux_repo_https_url" {
  description = "HTTPS URL GitHub репозиторію для Flux"
  value       = github_repository.flux_repo.http_clone_url
}

output "flux_repo_clone_url" {
  description = "SSH URL GitHub репозиторію для Flux (тільки для read-only ключів)"
  value       = github_repository.flux_repo.ssh_clone_url
}

#output "flux_deploy_key_pub" {
#  description = "Публічний ключ для deploy key Flux"
#  value       = tls_private_key.flux.public_key_openssh
#}

#output "flux_private_key" {
#  description = "Приватний ключ TLS (sensitive)"
#  value       = tls_private_key.flux.private_key_pem
#  sensitive   = true
#}