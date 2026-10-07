#!/usr/bin/env bash
# Source: https://lotusinputmethod.github.io (fcitx5-lotus apt repo, signed key from fcitx5-lotus.pages.dev)
set -euo pipefail
LIST=/etc/apt/sources.list.d/fcitx5-lotus.list
[ -f "$LIST" ] && exit 0
CODENAME="$(grep '^UBUNTU_CODENAME=' /etc/os-release | cut -d= -f2)"
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://fcitx5-lotus.pages.dev/pubkey.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/fcitx5-lotus.gpg
echo "deb [signed-by=/etc/apt/keyrings/fcitx5-lotus.gpg] https://fcitx5-lotus.pages.dev/apt/$CODENAME $CODENAME main" |
  sudo tee "$LIST" >/dev/null
