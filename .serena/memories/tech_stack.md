# Tech Stack

Full stack details: see `AGENTS.md` (Dotter, fish, mise, Brewfile/scoop, Lua nvim).

Non-obvious bits:
- Toolchain pins in `mise/config.toml`: just, node (latest+lts), bun, uv, rust — all "latest"
- Neovim plugin lockfile: `nvim-pack-lock.json`; formatting config `nvim/stylua.toml`
- OpenCode MCP servers in `opencode/opencode.jsonc`: deepwiki, exa, serena (serena = local stdio, `--context ide --project-from-cwd`)
- No build system; repo is config/Lua only