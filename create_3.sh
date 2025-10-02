#!/bin/bash
set -e

NAMESPACE=demo-helm
HR_NAME=kbot
GIT_REPO_URL="https://github.com/andreysvirid/gke-flux-infra.git"
GIT_BRANCH=develop
IMAGE_REPO="andreysvirid/kbot2"
CONFIGMAP_NAME=kbot-values
IMAGE_POLICY_NAME=kbot-policy
IMAGE_UPDATE_NAME=kbot-automation

echo "=== Создание namespace ==="
kubectl create ns $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo "=== Проверка секрета telegram-token ==="
kubectl get secret telegram-token -n $NAMESPACE || echo "Создайте секрет telegram-token перед запуском"

echo "=== Создание ConfigMap с values.yaml ==="
cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: $CONFIGMAP_NAME
data:
  values.yaml: |
    image:
      repository: $IMAGE_REPO
      tag: "v1.0.0-PLACEHOLDER"
    service:
      type: ClusterIP
      port: 80
    env:
      - name: TELEGRAM_TOKEN
        valueFrom:
          secretKeyRef:
            name: telegram-token
            key: token
EOF

echo "=== Создание HelmRelease ==="
cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: $HR_NAME
spec:
  interval: 1m
  chart:
    spec:
      chart: ./kbot
      sourceRef:
        kind: GitRepository
        name: kbot-repo
  valuesFrom:
    - kind: ConfigMap
      name: $CONFIGMAP_NAME
      valuesKey: values.yaml
EOF

echo "=== Создание ImageRepository ==="
cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageRepository
metadata:
  name: kbot-repo
spec:
  interval: 1m
  image: $IMAGE_REPO
EOF

echo "=== Создание ImagePolicy ==="
cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImagePolicy
metadata:
  name: $IMAGE_POLICY_NAME
spec:
  imageRepositoryRef:
    name: kbot-repo
  policy:
    semver:
      range: ">=v1.0.0"
EOF

echo "=== Создание ImageUpdateAutomation ==="
cat <<EOF | kubectl apply -n $NAMESPACE -f -
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageUpdateAutomation
metadata:
  name: $IMAGE_UPDATE_NAME
spec:
  interval: 1m
  sourceRef:
    kind: GitRepository
    name: kbot-repo
  git:
    checkout:
      ref:
        branch: $GIT_BRANCH
    commit:
      author:
        email: flux@users.noreply.github.com
        name: Flux
      messageTemplate: 'ci: update image tag to {{ .NewTag }}'
    push:
      branch: $GIT_BRANCH
  update:
    strategy: Setters
EOF

echo ""
echo "=== Проверка текущего состояния ==="

echo "HelmRelease status:"
kubectl get hr $HR_NAME -n $NAMESPACE

echo ""
echo "Текущий SHA из HelmChart:"
SHA=$(kubectl get helmchart demo-helm-$HR_NAME -n $NAMESPACE -o jsonpath="{.status.observedSourceArtifactRevision}" | cut -d"@" -f2)
echo $SHA

echo ""
echo "values.yaml в Git по этому SHA:"
git fetch origin $GIT_BRANCH >/dev/null 2>&1
git show $SHA:kbot/values.yaml || echo "values.yaml не найден в этом коммите"

echo ""
echo "Текущий образ на поде:"
kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=$HR_NAME -o jsonpath="{.items[0].spec.containers[0].image}" || echo "Pod не найден"
echo ""
