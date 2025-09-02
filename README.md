# GitOps розгортання PET-проєкту `kbot` у Kubernetes через FluxCD

Цей репозиторій демонструє повний GitOps-процес для PET-проєкту `kbot` з використанням **Terraform**, **GKE**, **FluxCD**, **Helm** та **GitHub Actions**.

---

## 🔹 Архітектура GitOps

```mermaid
flowchart TD
    %% Стилі компонентів
    classDef terraform fill:#f7df1e,stroke:#000,color:#000
    classDef kubernetes fill:#326ce5,stroke:#000,color:#fff
    classDef github fill:#24292f,stroke:#000,color:#fff
    classDef docker fill:#2496ed,stroke:#000,color:#fff
    classDef flux fill:#0097d6,stroke:#000,color:#fff
    classDef app fill:#28a745,stroke:#000,color:#fff
    classDef dev fill:#ff9f1a,stroke:#000,color:#000

    %% Компоненти і взаємодії
    TF[Terraform]:::terraform -->|Створює GKE кластер| K8s[Kubernetes Cluster]:::kubernetes
    TF -->|Генерує SSH ключі для Flux| GH[GitHub Repository]:::github
    GH -->|FluxCD підключається| K8s
    Dev[Розробник]:::dev -->|Commit / PR| GH
    GH -->|GitHub Actions: build & push Docker image| Docker[Docker Registry]:::docker
    Docker -->|Оновлює тег образу в Helm chart| GH
    FluxCD[FluxCD]:::flux -->|Синхронізація з Git| K8s
    K8s -->|Оновлює Deployment / HelmRelease| App[PET-проєкт (kbot) запущений]:::app
🔹 Розгортання кластера та Flux через Terraform
Клонуйте репозиторій:

bash
Копировать код
git clone git@github.com:your-org/your-repo.git
cd your-repo
Створіть файли змінних:

vars.tfvars:

hcl
Копировать код
GOOGLE_PROJECT = "my-gcp-project"
GOOGLE_REGION  = "us-central1"
GKE_NUM_NODES  = 3
GITHUB_OWNER   = "your-github-username"
secrets.tfvars:

hcl
Копировать код
GITHUB_TOKEN = "ghp_XXXXXXXXXXXXXXXXXXXXXXXX"
Важливо: GitHub token повинен мати права repo та admin:public_key.

Ініціалізація Terraform:

bash
Копировать код
terraform init -upgrade
Перевірка плану:

bash
Копировать код
terraform plan -var-file="vars.tfvars" -var-file="secrets.tfvars"
Застосування конфігурації:

bash
Копировать код
terraform apply -var-file="vars.tfvars" -var-file="secrets.tfvars"
🔹 HelmRelease для kbot (через Git)
Файл: charts/kbot/kbot-helmrelease.yaml

yaml
Копировать код
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: kbot
  namespace: default
spec:
  interval: 1m
  chart:
    spec:
      chart: ./charts/kbot
      sourceRef:
        kind: GitRepository
        name: flux-repo
  values:
    replicaCount: 2
    image:
      repository: your-dockerhub-username/kbot
      tag: latest
      pullPolicy: IfNotPresent
    service:
      type: ClusterIP
      port: 80
    resources:
      limits:
        cpu: 250m
        memory: 256Mi
      requests:
        cpu: 100m
        memory: 128Mi
Flux автоматично застосує цей HelmRelease у кластері після пушу змін у Git.

🔹 CI/CD через GitHub Actions
Workflow: .github/workflows/docker-helm.yml

yaml
Копировать код
name: Build & Deploy kbot

on:
  push:
    branches:
      - main
  pull_request:

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    env:
      IMAGE_NAME: your-dockerhub-username/kbot
      CHART_PATH: ./charts/kbot

    steps:
      - name: Checkout repository
        uses: actions/checkout@v3

      - name: Log in to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}

      - name: Build Docker image
        run: |
          docker build -t $IMAGE_NAME:latest .
      
      - name: Push Docker image
        run: |
          docker push $IMAGE_NAME:latest

      - name: Update Helm values.yaml
        run: |
          yq eval ".image.tag = \"latest\"" -i $CHART_PATH/values.yaml
          git config --global user.email "flux-bot@example.com"
          git config --global user.name "flux-bot"
          git add $CHART_PATH/values.yaml
          git commit -m "Update Docker image tag to latest [skip ci]" || echo "No changes to commit"
          git push origin main
🔹 Secrets у GitHub
DOCKER_USERNAME — логін Docker Hub

DOCKER_PASSWORD — пароль/токен Docker Hub

🔹 Перевірка
bash
Копировать код
# Статус Flux
kubectl get pods -n flux-system

# HelmRelease
kubectl get hr -n default

# Перевірка нового образу
kubectl describe hr kbot -n default
Новий тег образу повинен застосовуватись автоматично.

Podи перезапускаються з оновленим образом.

🔹 Outputs Terraform
bash
Копировать код
terraform output
Приклад:

ini
Копировать код
gke_cluster_name = "example-cluster"
gke_cluster_endpoint = "XX.XX.XX.XX"
flux_repo_https_url = "https://github.com/your-org/gke-flux-gitops.git"
flux_repo_clone_url = "git@github.com:your-org/gke-flux-gitops.git"
flux_deploy_key_pub = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..."
Примітка: приватний ключ позначений як sensitive і не показується у звичайному виводі.

Цей README тепер повністю відображає процес GitOps: Terraform створює кластер і репозиторій, GitHub Actions оновлює Docker-образ та Helm chart, Flux автоматично застосовує зміни у Kubernetes.




