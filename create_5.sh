#!/bin/bash
set -e

NAMESPACE="demo-helm"
HR_NAME="kbot"
GIT_SOURCE="kbot-repo"

echo "=== Проверка секрета ==="
if kubectl get secret telegram-token -n $NAMESPACE >/dev/null 2>&1; then
  echo "✅ Секрет telegram-token найден"
else
  echo "❌ Секрет telegram-token отсутствует в namespace $NAMESPACE"
  exit 1
fi

echo ""
echo "=== Очистка старых ресурсов ==="
kubectl delete pod -n $NAMESPACE -l app.kubernetes.io/name=$HR_NAME --ignore-not-found
kubectl delete hr $HR_NAME -n $NAMESPACE --ignore-not-found

echo ""
echo "=== Создание HelmRelease заново ==="
cat <<EOF | kubectl apply -f -
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: $HR_NAME
  namespace: $NAMESPACE
spec:
  interval: 1m
  chart:
    spec:
      chart: ./kbot
      sourceRef:
        kind: GitRepository
        name: $GIT_SOURCE
      version: "*"
EOF

echo ""
echo "=== Обновляем Git источник ==="
flux reconcile source git $GIT_SOURCE -n $NAMESPACE

echo ""
echo "=== Пересобираем HelmRelease с новым chart ==="
flux reconcile hr $HR_NAME -n $NAMESPACE --with-source

echo ""
echo "=== Получаем Git SHA, использованный Flux ==="
SHA=$(kubectl get helmchart demo-helm-$HR_NAME -n $NAMESPACE -o jsonpath="{.status.observedSourceArtifactRevision}" | cut -d"@" -f2)
echo "Git SHA: $SHA"

echo ""
echo "=== values.yaml на этом коммите ==="
git fetch origin develop >/dev/null 2>&1
git show $SHA:kbot/values.yaml || echo "values.yaml не найден на этом коммите"

echo ""
echo "=== Ожидаем новый Pod ==="
echo "Подождите, Flux деплоит HelmRelease..."
until kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=$HR_NAME -o jsonpath="{.items[0].status.phase}" 2>/dev/null | grep -q "Running"; do
    echo -n "."
    sleep 2
done
echo ""
POD_NAME=$(kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=$HR_NAME -o jsonpath="{.items[0].metadata.name}")
IMAGE=$(kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=$HR_NAME -o jsonpath="{.items[0].spec.containers[0].image}")

echo "✅ Pod запущен: $POD_NAME"
echo "✅ Образ: $IMAGE"

echo ""
echo "=== Последние 10 логов Pod ==="
kubectl logs -n $NAMESPACE $POD_NAME --tail=10 -f
