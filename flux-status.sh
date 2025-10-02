#!/bin/bash

NAMESPACE="demo-helm"
HR_NAME="kbot"
LABEL="app.kubernetes.io/name=kbot"

# Получаем имя текущего pod
POD_NAME=$(kubectl get pod -n $NAMESPACE -l $LABEL -o jsonpath="{.items[0].metadata.name}")

# Проверяем, найден ли pod
if [ -z "$POD_NAME" ]; then
  echo "Pod с лейблом $LABEL не найден в namespace $NAMESPACE"
  exit 1
fi

echo "Watching HelmRelease, pods and logs for pod: $POD_NAME in namespace $NAMESPACE"
echo "Press Ctrl+C to exit"

# Запускаем цикл обновления
while true; do
    clear
    echo "=== HelmRelease Status ==="
    flux get hr $HR_NAME -n $NAMESPACE
    echo ""

    echo "=== Pods Status ==="
    kubectl get pods -n $NAMESPACE
    echo ""

    echo "=== Last 10 lines of kbot logs ==="
    kubectl logs -n $NAMESPACE $POD_NAME --tail=10
    echo ""
    
    sleep 2
done
