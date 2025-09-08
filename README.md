# GKE + FluxCD + GitHub Actions + Helm (kbot demo)

Цей проєкт демонструє повний GitOps-процес:  
- розгортання кластера **GKE** через Terraform  
- встановлення **FluxCD**  
- налаштування **GitRepository** та **HelmRelease** для pet-проєкту **kbot**  
- автоматичне оновлення контейнерного образу через **GitHub Actions**  

---

## 🚀 Розгортання кластера та Flux через Terraform

### 1. Створення репозиторію
Створи новий GitHub-репозиторій:
👉 [andreysvirid/gke-flux-infra](https://github.com/andreysvirid/gke-flux-infra)

### 2. Ініціалізація Terraform
```bash
terraform init
terraform plan -var="github_token=$GITHUB_TOKEN"
terraform apply -var="github_token=$GITHUB_TOKEN" -auto-approve
🔧 Налаштування HelmRelease для kbot

apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: kbot
  namespace: demo-helm
spec:
  releaseName: kbot
  interval: 1m
  chart:
    spec:
      chart: ./charts/kbot2
      sourceRef:
        kind: GitRepository
        name: gke-flux-infra
        namespace: flux-system
  values:
    image:
      repository: andreysvirid/kbot2
      tag: "v1.0.0-cdc3eb0"
⚠️ Перед застосуванням переконайся, що неймспейс створений:

kubectl create namespace demo-helm
Застосування у develop:

git checkout develop
git add clusters/dev/kbot-helmrelease.yaml
git commit -m "Add HelmRelease for kbot"
git push origin develop
Flux автоматично застосує HelmRelease у кластері після пушу.

📦 Встановлення Flux у кластері

kubectl create namespace flux-system
flux install \
  --namespace=flux-system \
  --components=source-controller,kustomize-controller,helm-controller,notification-controller
🔗 Підключення Flux до GitHub-репозиторію

export GITHUB_USER=andreysvirid
export GITHUB_REPO=gke-flux-infra
export GITHUB_TOKEN=<тут_твій_token>

flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=$GITHUB_REPO \
  --branch=develop \
  --path=./clusters/dev \
  --personal
Ця команда:

створить у кластері всі ресурси Flux
налаштує GitRepository у flux-system
підключить каталог clusters/dev як джерело маніфестів

✅ Перевірка Flux
# GitRepository
kubectl get gitrepository -n flux-system
kubectl describe gitrepository gke-flux-infra -n flux-system

# Синхронізація
flux get kustomizations -A
flux reconcile kustomization flux-system --with-source
⚙️ CI/CD через GitHub Actions
У репозиторії створюємо .github/workflows/build.yaml:

name: Build & Deploy kbot

on:
  push:
    branches:
      - main
      - develop

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Docker
        run: echo "${{ secrets.DOCKERHUB_TOKEN }}" | docker login -u "${{ secrets.DOCKERHUB_USERNAME }}" --password-stdin

      - name: Build Docker image
        run: |
          IMAGE_TAG=$(git rev-parse --short HEAD)
          echo "IMAGE_TAG=$IMAGE_TAG" >> $GITHUB_ENV
          docker build -t andreysvirid/kbot2:$IMAGE_TAG .

      - name: Push Docker image
        run: docker push andreysvirid/kbot2:${{ env.IMAGE_TAG }}

      - name: Update HelmRelease
        run: |
          sed -i "s|tag:.*|tag: \"${{ env.IMAGE_TAG }}\"|g" clusters/dev/kbot-helmrelease.yaml
          git config user.name github-actions
          git config user.email github-actions@github.com
          git add clusters/dev/kbot-helmrelease.yaml
          git commit -m "Update kbot image to ${{ env.IMAGE_TAG }}"
          git push origin develop
🔑 Необхідні secrets:
DOCKERHUB_USERNAME
DOCKERHUB_TOKEN
GITHUB_TOKEN (вбудований у GitHub, можна використовувати напряму)

🔍 Перевірка розгортання

# HelmRelease
kubectl get helmrelease kbot -n demo-helm -o yaml | grep -A3 "image:"
# Deployment
kubectl get deployment kbot -n demo-helm -o yaml | grep image:
# Pod
kubectl get pods -n demo-helm -l app=kbot
kubectl describe pod -n demo-helm <pod-name> | grep -i image:


🎯 Результат
✅ Розгорнутий кластер GKE
✅ Встановлений Flux
✅ Налаштований GitRepository та HelmRelease для kbot
✅ GitHub Actions будує Docker-образ, пушить у DockerHub, оновлює HelmRelease
✅ Flux автоматично підтягує новий образ у кластер 🚀

