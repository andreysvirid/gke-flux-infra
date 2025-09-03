# GKE + FluxCD + GitHub Actions + Helm (kbot demo)

Цей проект демонструє повний GitOps-процес: розгортання кластеру GKE через Terraform, встановлення FluxCD, налаштування GitRepository та HelmRelease для PET-проєкту kbot, а також автоматичне оновлення контейнерного образу через GitHub Actions.

---

## Розгортання кластера та Flux через Terraform

### 1. Клонуйте репозиторій
```bash
git clone https://github.com/andreysvirid/gke-flux-infra.git
cd gke-flux-infra
2. Створіть файли змінних
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
⚠️ GitHub Token повинен мати права: repo та admin:public_key.

3. Ініціалізація Terraform
bash
Копировать код
terraform init -upgrade
4. Перевірка плану
bash
Копировать код
terraform plan -var-file="vars.tfvars" -var-file="secrets.tfvars"
5. Застосування конфігурації
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
У репозиторії → Settings → Secrets and variables → Actions додайте:

DOCKER_USERNAME — логін Docker Hub

DOCKER_PASSWORD — пароль/токен Docker Hub

Перевірка
Статус Flux
bash
Копировать код
kubectl get pods -n flux-system
HelmRelease
bash
Копировать код
kubectl get hr -n default
Перевірка нового образу
bash
Копировать код
kubectl describe hr kbot -n default
Pod-и мають перезапускатись з оновленим образом.

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
⚠️ Приватний ключ у виводі позначений як sensitive і не показується.

Результат
✅ Розгорнутий кластер GKE
✅ Встановлений Flux
✅ Налаштований GitRepository та HelmRelease для kbot
✅ Зміни в коді → GitHub Actions → новий Docker-образ → Flux автоматично оновлює застосунок у Kubernetes 🚀


