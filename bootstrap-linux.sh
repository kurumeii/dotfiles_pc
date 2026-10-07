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

command -v make >/dev/null 2>&1 || sudo apt-get install -y build-essential

brew bundle --file="$DIR/Brewfile"

# Sync apt: add third-party repos via apt/repos/*.sh (each is idempotent, sources noted inside),
# then install missing packages from apt/packages.txt.
if command -v apt-get >/dev/null 2>&1 && [ -f "$DIR/apt/packages.txt" ]; then
  apt_before="$(ls /etc/apt/sources.list.d 2>/dev/null | md5sum)"
  for repo in "$DIR"/apt/repos/*.sh; do
    [ -f "$repo" ] || continue
    bash "$repo" || echo "warning: apt repo script failed: $repo" >&2
  done
  [ "$apt_before" != "$(ls /etc/apt/sources.list.d 2>/dev/null | md5sum)" ] && sudo apt-get update
  missing=()
  while read -r pkg _; do
    case "$pkg" in "" | \#*) continue ;; esac
    dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
  done <"$DIR/apt/packages.txt"
  if [ "${#missing[@]}" -gt 0 ]; then
    sudo apt-get install -y "${missing[@]}" ||
      echo "warning: apt install failed for: ${missing[*]}" >&2
  fi
fi

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
# Extract each AppImage's own .desktop + icons and point Exec at the stable (symlinked) AppImage path.
APPS_DIR="$HOME/.local/share/applications"
ICONS_DIR="$HOME/.local/share/icons/hicolor"
mkdir -p "$APPS_DIR" "$ICONS_DIR"
for APPIMAGE in "$HOME"/Applications/*.AppImage; do
  [ -x "$APPIMAGE" ] || continue
  name="$(basename "$APPIMAGE" .AppImage)"
  DESKTOP_FILE="$APPS_DIR/${name,,}.desktop"
  [ -f "$DESKTOP_FILE" ] && continue
  TMP="$(mktemp -d)"
  (cd "$TMP" && for pat in '*.desktop' 'usr/share/applications/*' 'usr/share/icons/*'; do
    "$APPIMAGE" --appimage-extract "$pat" >/dev/null 2>&1 || true
  done)
  src="$(find -L "$TMP/squashfs-root" -maxdepth 1 -name '*.desktop' -type f 2>/dev/null | head -n1)"
  if [ -z "$src" ]; then
    echo "warning: no .desktop found in $APPIMAGE" >&2
    rm -rf "$TMP"
    continue
  fi
  [ -d "$TMP/squashfs-root/usr/share/icons/hicolor" ] &&
    cp -rn "$TMP/squashfs-root/usr/share/icons/hicolor/." "$ICONS_DIR/" 2>/dev/null
  sed -E -e '/^TryExec=/d' -e "s|^Exec=[^ ]+|Exec=$APPIMAGE|" -e "/^Exec=/a TryExec=$APPIMAGE" \
    "$src" >"$TMP/out.desktop" && mv "$TMP/out.desktop" "$DESKTOP_FILE"
  rm -rf "$TMP"
done

# Brew's wezterm formula ships no .desktop or icon either.
WEZTERM_BIN="$(command -v wezterm || true)"
WEZTERM_DESKTOP="$APPS_DIR/wezterm.desktop"
if [ -n "$WEZTERM_BIN" ] && [ ! -f "$WEZTERM_DESKTOP" ]; then
  WEZTERM_ICON="$ICONS_DIR/128x128/apps/org.wezfurlong.wezterm.png"
  if [ ! -f "$WEZTERM_ICON" ]; then
    mkdir -p "$(dirname "$WEZTERM_ICON")"
    curl -fsSL -o "$WEZTERM_ICON" \
      https://raw.githubusercontent.com/wezterm/wezterm/main/assets/icon/terminal.png ||
      echo "warning: could not download wezterm icon" >&2
  fi
  cat >"$WEZTERM_DESKTOP" <<EOF
[Desktop Entry]
Name=WezTerm
Comment=Wez's Terminal Emulator
Keywords=shell;prompt;command;commandline;cmd;
Icon=org.wezfurlong.wezterm
StartupWMClass=org.wezfurlong.wezterm
TryExec=$WEZTERM_BIN
Exec=$WEZTERM_BIN start --cwd .
Type=Application
Categories=System;TerminalEmulator;Utility;
Terminal=false
EOF
fi
update-desktop-database "$APPS_DIR" 2>/dev/null || true
gtk-update-icon-cache -f -t "$ICONS_DIR" 2>/dev/null || true

# Install Neovim plugins from nvim-pack-lock.json (vim.pack restores the whole lockfile on first use).
# Requires the nvim config to be deployed first (dotter deploy).
if command -v nvim >/dev/null 2>&1 && [ -f "$HOME/.config/nvim/init.lua" ]; then
  nvim --headless +qa 2>&1 || echo "warning: nvim plugin install failed; run nvim manually" >&2
fi
