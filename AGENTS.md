# Dotfiles — Agent Instructions

Cross-platform (Linux + Windows) personal dotfiles managed by **Dotter** with Handlebars templating.

## Architecture

**Deployment tool:** [Dotter](https://github.com/SuperCuber/dotter) — see `.dotter/global.toml` for file mappings and `.dotter/local.toml` (gitignored) for machine-specific variables/packages.

**Templating:** Config files use `{{variable}}` and `{{#if dotter.packages.linux}}` / `{{#if dotter.packages.windows}}` conditionals. Variables are defined in `.dotter/local.toml`; examples in `.dotter/local.example.toml`.

**Bootstrap:** `bootstrap-linux.sh` installs Homebrew (Linuxbrew), runs `brew bundle --file=Brewfile`, sets up KeePassXC desktop entry, and bootstraps Neovim plugins.

## Directory Layout

| Directory           | Tool                                 | Deployed to               |
| ------------------- | ------------------------------------ | ------------------------- |
| `fish/`             | Fish shell (config + plugins)        | `~/.config/fish`          |
| `nvim/`             | Neovim (Lua config, plugins, after/) | `~/.config/nvim`          |
| `kitty/`            | Kitty terminal (Linux only)          | `~/.config/kitty`         |
| `wezterm/`          | WezTerm terminal                     | `~/.config/wezterm`       |
| `windows-terminal/` | Windows Terminal settings            | Windows AppData path      |
| `powershell/`       | PowerShell profile + scripts         | `~/Documents/PowerShell/` |
| `lazygit/`          | Lazygit                              | `~/.config/lazygit`       |
| `bat/`              | bat (syntax highlighting cat)        | `~/.config/bat`           |
| `btop/`             | btop (system monitor)                | `~/.config/btop`          |
| `yazi/`             | Yazi file manager                    | `~/.config/yazi`          |
| `fastfetch/`        | Fastfetch (system info)              | `~/.config/fastfetch`     |
| `flameshot/`        | Flameshot (screenshots, Linux)       | `~/.config/flameshot`     |
| `rg/`               | ripgrep config                       | `~/.config/rg`            |
| `gh/`               | GitHub CLI config                    | `~/.config/gh`            |
| `herdr/`            | Herdr terminal multiplexer           | `~/.config/herdr`         |
| `mise/`             | mise (dev tool version manager)      | `~/.config/mise`          |
| `mimocode/`         | MimoCode AI coding tool              | `~/.config/mimocode`      |
| `opencode/`         | OpenCode AI coding tool              | `~/.config/opencode`      |
| `commandcode/`      | Command Code commands                | `~/.commandcode/commands` |
| `.commandcode/`     | Command Code settings, MCP, skills   | `~/.commandcode/`         |

**Standalone files:**

- `gitconfig` → `~/.gitconfig` (templated: username, email, credential helper, OS-specific diff)
- `vimrc` → `~/.vimrc` (legacy Vim config)
- `andrew.omp.json` → `~/andrew.omp.json` (Oh My Posh prompt theme, symlinked)
- `Brewfile` — Homebrew package manifest (Linux)
- `scoop-bak.json` — Scoop package backup (Windows)
- `winget-apps.bak` — Winget package backup (Windows)

## Shell Setup

**Primary shell:** Fish. Config at `fish/config.fish` initializes: mise, oh-my-posh, fastfetch, zoxide, fzf, herdr. Aliases: `cd→z`, `grep→rg`, `ll→eza --long --icons`, `ls→eza`, `vim→nvim`, `cat→bat`.

**Dev tools via mise:** node (latest + lts), bun, uv, rust — all latest.

**Prompt:** Oh My Posh with `andrew.omp.json` theme (session, path, git, node segments).

## Dotter Workflow

```bash
# Deploy configs (from repo root)
dotter deploy

# Deploy with specific packages
dotter deploy --packages linux
dotter deploy --packages default windows
```

**local.toml** (not committed) must define: `username`, `email`, `pc_name`, and API key variables. See `.dotter/local.example.toml` for the template.

## Conventions

- Fish is the shell, not bash/zsh — new shell config goes in Fish syntax
- Neovim is the primary editor — Lua config in `nvim/`, not vimscript
- All tool configs use their XDG paths (`~/.config/<tool>`)
- API keys are injected via Dotter templating from KeePassXC lookups (see `local.example.toml`)
- Windows-specific files are gated with `[windows.files]` in dotter config; Linux with `[linux.files]`
- Git uses `difft` (difftastic) as external diff tool and `nvim` as merge tool

## AI/Agent Skills

Skills are installed in three locations for three agent tools:

- `.commandcode/skills/` — Command Code skills (cavecrew, caveman variants, herdr)
- `.agents/skills/` — Agents skills (herdr)
- `.claude/skills/` — Claude skills (herdr)

The `skills-lock.json` tracks installed skill sources and hashes.
