echo "=== HelmRelease Status ==="
kubectl get helmrelease kbot -n demo-helm
echo ""

echo "=== HelmChart SHA (Git commit) ==="
SHA=$(kubectl get helmchart demo-helm-kbot -n demo-helm -o jsonpath="{.status.observedSourceArtifactRevision}" | cut -d"@" -f2 | sed 's/sha1://')
echo $SHA
echo ""

echo "=== values.yaml at this commit ==="
git fetch origin develop >/dev/null 2>&1
git show $SHA:kbot/values.yaml || echo "values.yaml not found at this commit"
echo ""

echo "=== Tag from values.yaml ==="
git show $SHA:kbot/values.yaml | grep tag || echo "tag not found"
echo ""

echo "=== Current Pod Image ==="
kubectl get pod -n demo-helm -l app.kubernetes.io/name=kbot -o jsonpath="{.items[0].spec.containers[0].image}" || echo "Pod not found"
echo ""
