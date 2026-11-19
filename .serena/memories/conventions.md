# Conventions

Style rules: see `AGENTS.md` Conventions section.

Gotchas not covered there:
- Skills live in 3 parallel trees (`.commandcode/skills/`, `.agents/skills/`, `.claude/skills/`) — keep them in sync and update `skills-lock.json` when adding one
- Windows-only configs (powershell, windows-terminal) cannot be smoke-tested from Linux — flag for user verification
- New tool = new top-level dir + mapping entry in `.dotter/global.toml` (choose default/linux/windows section deliberately)