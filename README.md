# GKE + FluxCD + GitHub Actions + Helm (kbot demo)

## Архітектура

```mermaid
flowchart TD
    TF[Terraform] --> K8s[Kubernetes Cluster]
    TF --> GH[GitHub Repository]
    GH --> FluxCD[FluxCD]
    Dev[Розробник] --> GH
    GH --> Docker[Docker Registry]
    Docker --> GH
    FluxCD --> K8s
    K8s --> App[kbot]
Розгортання кластера та Flux через Terraform
Клонуйте репозиторій:

bash
Копировать код
git clone git@github.com:your-org/your-repo.git
cd your-repo
Створіть файли змінних:

vars.tfvars

hcl
Копировать код
GOOGLE_PROJECT = "my-gcp-project"
GOOGLE_REGION  = "us-central1"
GKE_NUM_NODES  = 3
GITHUB_OWNER   = "your-github-username"
secrets.tfvars

hcl
Копировать код
GITHUB_TOKEN = "ghp_XXXXXXXXXXXXXXXXXXXXXXXX"
⚠️ Token GitHub має права: repo та admin:public_key.

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
HelmRelease для kbot
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
CI/CD через GitHub Actions
Файл: .github/workflows/docker-helm.yml

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
      - uses: actions/checkout@v3
      - name: Log in to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      - run: docker build -t $IMAGE_NAME:latest .
      - run: docker push $IMAGE_NAME:latest
      - run: |
          yq eval ".image.tag = \"latest\"" -i $CHART_PATH/values.yaml
          git config --global user.email "flux-bot@example.com"
          git config --global user.name "flux-bot"
          git add $CHART_PATH/values.yaml
          git commit -m "Update Docker image tag to latest [skip ci]" || echo "No changes to commit"
          git push origin main
Secrets у GitHub
DOCKER_USERNAME — логін Docker Hub

DOCKER_PASSWORD — пароль/токен Docker Hub

Перевірка
bash
Копировать код
kubectl get pods -n flux-system
kubectl get hr -n default
kubectl describe hr kbot -n default
Outputs Terraform
bash
Копировать код
terraform output
Приклад:

ini
Копировать код
gke_cluster_name     = "example-cluster"
gke_cluster_endpoint = "XX.XX.XX.XX"
flux_repo_https_url  = "https://github.com/your-org/gke-flux-gitops.git"
flux_repo_clone_url  = "git@github.com:your-org/gke-flux-gitops.git"
flux_deploy_key_pub  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ..."
✅ Результат:

Розгорнутий кластер GKE

Встановлений Flux

Налаштований GitRepository та HelmRelease для kbot

Зміни в коді → GitHub Actions → новий Docker-образ → Flux автоматично оновлює застосунок у Kubernetes





