#!/usr/bin/env bash
# Source: https://launchpad.net/~quentiumyt/+archive/ubuntu/flameshot (PPA by Quentin Lienhardt)
set -euo pipefail
compgen -G '/etc/apt/sources.list.d/quentiumyt-ubuntu-flameshot-*' >/dev/null && exit 0
sudo add-apt-repository -y ppa:quentiumyt/flameshot
