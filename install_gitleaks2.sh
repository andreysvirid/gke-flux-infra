GITLEAKS_VERSION=$(curl -s https://api.github.com/repos/gitleaks/gitleaks/releases/latest \
  | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

wget -qO gitleaks.tar.gz "https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz"
sudo tar -xzf gitleaks.tar.gz -C /usr/local/bin gitleaks
rm gitleaks.tar.gz
gitleaks version
