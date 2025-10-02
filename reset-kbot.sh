#!/bin/bash

NAMESPACE="demo-helm"
HR_NAME="kbot"
SECRET_NAME="telegram-token"

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
echo "=== Очистка старых ресурсов ==="
kubectl delete pod,deploy,svc -l app.kubernetes.io/name=kbot -n $NAMESPACE --ignore-not-found

echo ""
echo "=== Удаление старого HelmRelease (если есть) ==="
flux delete hr $HR_NAME -n $NAMESPACE --ignore-not-found

echo ""
echo "=== Создание HelmRelease заново ==="
flux create hr $HR_NAME \
  --namespace=$NAMESPACE \
  --chart=./kbot \
  --source=GitRepository/kbot-repo \
  --values=./kbot/values.yaml \
  --interval=1m

echo ""
echo "✅ HelmRelease создан. Подождите пару секунд, затем проверьте pod и логи:"
echo "kubectl get pods -n $NAMESPACE"
echo "kubectl logs -n $NAMESPACE -f \$(kubectl get pod -n $NAMESPACE -l app.kubernetes.io/name=kbot -o jsonpath='{.items[0].metadata.name}')"
echo "flux get hr $HR_NAME -n $NAMESPACE"
