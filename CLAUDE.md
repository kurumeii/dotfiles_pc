# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal dotfiles managed by [dotter](https://github.com/SuperCuber/dotter) (Rust dotfile manager/templater), primarily for Windows (PowerShell) with a secondary Linux/fish target. There is no build, lint, or test suite — this is configuration, not software. "Correctness" means: does `dotter deploy` render/link cleanly, and does the resulting config work in the target app.

## Deploying changes

```
dotter deploy          # render templates + create symlinks/hardlinks at their real target paths
dotter deploy --dry-run # preview without touching anything
dotter undeploy         # remove deployed files
```

Editing a file in this repo does **not** automatically take effect in the real app — you must `dotter deploy` after changes, unless the target is specifically a symlink/hardlink into a live-edited location (e.g. `powershell/Microsoft.PowerShell_profile.ps1`, see its own README).

## Architecture: how a file gets from here to a real config path

`.dotter/global.toml` is the source of truth for *where* each file/dir in this repo is deployed (per-OS, under `[default.files]`, `[windows.files]`, `[linux.files]`). `.dotter/cache.toml` (generated, not hand-edited) shows the resolved mapping and — critically — which files are plain **symlinks** vs which are **templates**:

- **Symlinks** (most files): deployed byte-for-byte as-is.
- **Templates** (Handlebars): `gitconfig`, `powershell/Microsoft.PowerShell_profile.ps1`, `fish/config.fish`, `nvim/lua/config/options.lua`. These contain `{{variable}}` / `{{#if ...}}` syntax resolved from `[variables]` in `.dotter/local.toml` + `.dotter/global.toml` at deploy time (e.g. `gitconfig` branches `credential.helper` on `{{#if dotter.packages.linux}}`).

When editing one of the four template files, remember the `{{...}}` syntax is Handlebars, not the target shell/language — don't "fix" it as if it were broken PowerShell/fish/lua/gitconfig syntax.

`.dotter/global.toml` is tracked; `.dotter/local.toml` (machine name, secrets, active `packages`) is gitignored and machine-specific — `.dotter/local.example.toml` is the tracked template for it. On non-primary machines, secret values in `local.toml` are meant to be shell-outs to `keepassxc-cli`/`gh auth token` rather than literal keys (see `local.example.toml`).

## Layout

Each top-level directory is one app's config, deployed to that app's real config location per `global.toml` (e.g. `nvim/` → `~/.config/nvim`, `lazygit/config.yml` → `~/.config/lazygit/config.yml`). `.claude/` is itself deployed to the real `~/.claude/` — so `.claude/settings.json` in this repo *is* the live Claude Code settings file for this machine.

- `nvim/` — LazyVim-style config built on the `mini.nvim` ecosystem (most plugins under `nvim/lua/plugins/mini/` are individual `mini.*` modules, not a monolithic `mini.nvim` setup call).
- `powershell/` — has its own `README.md` documenting a deliberately perf-tuned profile (deferred module imports, cached shell-integration output). Read that README before touching `Microsoft.PowerShell_profile.ps1`; don't reintroduce blocking `Invoke-Expression`/`Import-Module` calls at the top level.
- `lazygit/config.yml`, `gh/`, `mise/config.toml`, `wezterm/`, `yazi/`, `bat/`, `btop/`, `rg/`, `windows-terminal/` — single-file-ish app configs, generally safe to edit directly and redeploy.

## Conventions

- Windows is the primary target; keep `[linux.files]` / fish support working but don't assume it's exercised as often.
- Prefer editing the *source* file in this repo, never the deployed target path directly (it'll be a symlink/hardlink back here anyway, or will get clobbered on next deploy).
- This repo enables the **ponytail** Claude Code plugin (`.claude/settings.json`) — lean toward minimal, native-feature-first solutions when editing configs here.
