#!/usr/bin/env bash
set -e

# Визначаємо ОС
OS=$(uname -s | tr '[:upper:]' '[:lower:]')

echo "[gitleaks] Installing for $OS ..."

# Метод через curl | sh (офіційна інсталяція)
curl -sSfL https://raw.githubusercontent.com/gitleaks/gitleaks/master/install.sh | sh

echo "[gitleaks] Installed successfully!"
