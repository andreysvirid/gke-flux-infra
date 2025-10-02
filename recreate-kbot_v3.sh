#!/bin/bash

NAMESPACE="demo-helm"
HR_NAME="kbot"
GIT_SOURCE="kbot-repo"
SECRET_NAME="telegram-token"
GIT_URL="https://github.com/andreysvirid/gke-flux-infra"
GIT_BRANCH="develop"

echo "=== Проверка секрета ==="
if ! kubectl get secret $SECRET_NAME -n $NAMESPACE &>/dev/null; then
  echo "❌ Секрет $SECRET_NAME не найден в namespace $NAMESPACE!"
  echo "Создайте секрет перед запуском скрипта:"
  echo "kubectl create secret generic $SECRET_NAME --from-literal=token=<TELEGRAM_TOKEN> -n $NAMESPACE"
  exit 1
else
  echo "✅ Секрет $SECRET_NAME найден"
fi

echo ""
echo "=== Очистка старых pod/deploy/service ==="
kubectl delete pod,deploy,svc -l app.kubernetes.io/name=kbot -n $NAMESPACE --ignore-not-found

echo ""
echo "=== Удаление старого HelmRelease (если есть) ==="
if flux get hr $HR_NAME -n $NAMESPACE &>/dev/null; then
  flux delete hr $HR_NAME -n $NAMESPACE
fi

echo ""
echo "=== Удаление старого GitRepository (если есть) ==="
if flux get source git $GIT_SOURCE -n $NAMESPACE &>/dev/null; then
  flux delete source git $GIT_SOURCE -n $NAMESPACE
fi

echo ""
echo "=== Создание GitRepository заново ==="
flux create source git $GIT_SOURCE \
  --url=$GIT_URL \
  --branch=$GIT_BRANCH \
  --interval=1m \
  -n $NAMESPACE

echo ""
echo "=== Создание HelmRelease заново ==="
kubectl apply -f kbot-helmrelease.yaml

echo ""
echo "✅ Процесс запущен. Проверяйте pod и HelmRelease:"
echo "kubectl get pods -n $NAMESPACE -w"
echo "flux get hr $HR_NAME -n $NAMESPACE"
echo "kubectl logs -n $NAMESPACE -f \$(kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=kbot -o jsonpath='{.items[0].metadata.name}')"
