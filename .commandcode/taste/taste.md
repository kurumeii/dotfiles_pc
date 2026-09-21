# Taste Preferences

## Environment & Tooling

- Uses **dotter** as their dotfile manager; dotfiles repo is at `~/.pc_dotfiles`. Confidence: 0.9
- Prefers symbolic links (managed via dotter's `global.toml`) to keep config files in sync from the dotfiles repo. Confidence: 0.85
- Inside the dotfiles repo, prefers **no dot prefix** on directory/file names (e.g., `commandcode/` not `.commandcode/`), matching the convention used by other entries like `bat`, `nvim`, `opencode`. Confidence: 0.85
- On Windows (paths under `C:\Users\andrew.nguyen1`). Confidence: 0.95
