#!/usr/bin/env bash
# Source: https://helpcenter.onlyoffice.com/desktop/installation/desktop-install-ubuntu.aspx
set -euo pipefail
LIST=/etc/apt/sources.list.d/onlyoffice.list
[ -f "$LIST" ] && exit 0
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p -m 700 "$HOME/.gnupg"
gpg --no-default-keyring --keyring "gnupg-ring:$TMP/onlyoffice.gpg" \
  --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys CB2DE8E5
chmod 644 "$TMP/onlyoffice.gpg"
sudo install -o root -g root -m 644 "$TMP/onlyoffice.gpg" /usr/share/keyrings/onlyoffice.gpg
echo 'deb [signed-by=/usr/share/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main' |
  sudo tee "$LIST" >/dev/null
