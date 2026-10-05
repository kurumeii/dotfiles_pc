#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v brew >/dev/null 2>&1; then
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

BREW_BIN="/home/linuxbrew/.linuxbrew/bin/brew"
if ! command -v brew >/dev/null 2>&1 && [ -x "$BREW_BIN" ]; then
  eval "$("$BREW_BIN" shellenv)"
fi

FISH_CONF="$HOME/.config/fish/conf.d/brew.fish"
if [ -d "$HOME/.config/fish" ]; then
  mkdir -p "$(dirname "$FISH_CONF")"
  grep -q linuxbrew "$FISH_CONF" 2>/dev/null || echo 'eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)' >"$FISH_CONF"
fi

command -v make >/dev/null 2>&1 || sudo apt-get install -y build-essential

brew bundle --file="$DIR/Brewfile"

# Herdr plugins from herdr/plugins.txt (idempotent)
if command -v herdr >/dev/null 2>&1 && [ -f "$DIR/herdr/plugins.txt" ]; then
  installed="$(herdr plugin list 2>/dev/null || true)"
  while read -r repo ref _; do
    case "$repo" in "" | \#*) continue ;; esac
    grep -q "github:${repo}@" <<<"$installed" && continue
    herdr plugin install -y ${ref:+--ref "$ref"} "$repo" ||
      echo "warning: could not install herdr plugin $repo" >&2
  done <"$DIR/herdr/plugins.txt"
fi

# Cask AppImages land in ~/Applications without a .desktop entry, so GNOME's launcher can't see them.
APPIMAGE="$HOME/Applications/KeePassXC.AppImage"
DESKTOP_FILE="$HOME/.local/share/applications/keepassxc.desktop"
if [ -x "$APPIMAGE" ] && [ ! -f "$DESKTOP_FILE" ]; then
  TMP_ICONS="$(mktemp -d)"
  (cd "$TMP_ICONS" && "$APPIMAGE" --appimage-extract 'usr/share/icons' >/dev/null 2>&1) || true
  mkdir -p "$HOME/.local/share/icons/hicolor/scalable/apps"
  cp "$TMP_ICONS/squashfs-root/usr/share/icons/hicolor/scalable/apps/keepassxc.svg" \
    "$HOME/.local/share/icons/hicolor/scalable/apps/keepassxc.svg" 2>/dev/null ||
    echo "warning: could not extract keepassxc icon" >&2
  rm -rf "$TMP_ICONS"
  cat >"$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=KeePassXC
GenericName=Password Manager
Comment=Community-driven port of the Windows application "KeePass Password Safe"
Exec=$APPIMAGE %f
TryExec=$APPIMAGE
Icon=keepassxc
StartupWMClass=keepassxc
StartupNotify=false
Terminal=false
Type=Application
Categories=Utility;Security;Qt;
MimeType=application/x-keepass2;
SingleMainWindow=true
X-GNOME-SingleWindow=true
Keywords=security;privacy;password-manager;yubikey;password;keepass;
EOF
  update-desktop-database "$HOME/.local/share/applications" 2>/dev/null || true
  gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
fi

# Install Neovim plugins from nvim-pack-lock.json (vim.pack restores the whole lockfile on first use).
# Requires the nvim config to be deployed first (dotter deploy).
if command -v nvim >/dev/null 2>&1 && [ -f "$HOME/.config/nvim/init.lua" ]; then
  nvim --headless +qa 2>&1 || echo "warning: nvim plugin install failed; run nvim manually" >&2
fi
