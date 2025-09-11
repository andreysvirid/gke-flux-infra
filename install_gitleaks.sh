#!/usr/bin/env bash
set -e

# Отримуємо останню версію
VERSION=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest \
  | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

if [ -z "$VERSION" ]; then
  echo "[gitleaks] ❌ Could not fetch latest version"
  exit 1
fi

echo "[gitleaks] Latest version is v$VERSION"

URL="https://github.com/gitleaks/gitleaks/releases/download/v${VERSION}/gitleaks_${VERSION}_linux_x64.tar.gz"
echo "[gitleaks] Downloading from $URL ..."

curl -sSL "$URL" -o /tmp/gitleaks.tar.gz || { echo "[gitleaks] ❌ Download failed"; exit 1; }
tar -xzf /tmp/gitleaks.tar.gz -C /tmp gitleaks
sudo mv /tmp/gitleaks /usr/local/bin/
sudo chmod +x /usr/local/bin/gitleaks
rm /tmp/gitleaks.tar.gz

echo "[gitleaks] ✅ Installed successfully!"
gitleaks version