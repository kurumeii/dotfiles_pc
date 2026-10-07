#!/usr/bin/env bash
# Source: https://teamsforlinux.de (manual steps; the site's curl|sudo bash installer is deliberately not used)
set -euo pipefail
compgen -G '/etc/apt/sources.list.d/teams-for-linux-packages.*' >/dev/null && exit 0
sudo mkdir -p /etc/apt/keyrings
sudo wget -qO /etc/apt/keyrings/teams-for-linux.asc https://repo.teamsforlinux.de/teams-for-linux.asc
echo "deb [signed-by=/etc/apt/keyrings/teams-for-linux.asc arch=$(dpkg --print-architecture)] https://repo.teamsforlinux.de/debian/ stable main" |
  sudo tee /etc/apt/sources.list.d/teams-for-linux-packages.list >/dev/null
