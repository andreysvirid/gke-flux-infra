variable "GOOGLE_PROJECT" {
  description = "ID Google Cloud проекту"
  type        = string
}

#variable "GOOGLE_PROJECT" {
#  type        = string
#  description = "GCP project ID"
#  default     = "andreysviridproject1"
#}


variable "GOOGLE_REGION" {
  description = "Регіон для створення ресурсу"
  type        = string
}

#variable "GOOGLE_REGION" {
#  type        = string
#  description = "GCP region/zone"
#  default     = "europe-west1-b"
#}

variable "GKE_NUM_NODES" {
  description = "Кількість вузлів для GKE кластеру"
  type        = number
}

#variable "GKE_NUM_NODES" {
#  type        = number
#  description = "Number of nodes in GKE cluster"
#  default     = 1
#}

variable "GITHUB_OWNER" {
  type        = string
  description = "GitHub username or organization name (used for Flux repo)"
}

variable "GITHUB_TOKEN" {
  type        = string
  description = "GitHub token with repo and workflow permissions"
  sensitive   = true
}