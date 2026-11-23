# Guardrails — do not repeat these

## Icons are never glyphs
- Never use a unicode/ASCII glyph (`×`, `+`, `−`, `→`, `✓`, `☰`) as an icon. Use the
  repo's lucide wrapper from `src/shared/icons/<name>.tsx`; if the icon is missing,
  create the wrapper file (same shape as the existing ones) first.
- This holds for every framework/project, not just BookNest.

## Never modify file content through the shell
- Editing files with `sed`, `python`/`python3` scripts, `perl -i`, `awk`, or
  `cat > file` heredocs is forbidden. No exceptions, no "last resort".
- Use the editor's file tools, or Serena: `s.fs.create_text_file`,
  `s.edit.replace_content`, `s.fs.read_file`, `s.lsp`/`s.fs` navigation.
- If a tool cannot express the change, say so and ask — do not reach for a shell
  text processor. Shell is for running builds, tests, git and read-only checks
  (`cat`, `grep -n`, `ls`), never for writing content.
- Match the surrounding code exactly: indentation style, prettier/biome rules,
  import ordering; run the project formatter after edits instead of hand-formatting.

## Verify visual output before claiming it works
- After UI work, drive the real page (browser MCP) and look: layout, overflow at
  390px and 320px, drawer open/closed, role variants (guest, buyer, staff,
  sysadmin). Server-rendered HTML assertions alone are not evidence.
