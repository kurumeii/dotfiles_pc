## Code search preference: ast-grep over grep

When searching for code patterns (function calls, control flow, imports, type usage, API calls), use `ast-grep` instead of the `grep` tool or `grep` command. It is language-aware and matches AST structure, not text.

Use `ast-grep` with:
- `-p '<pattern>'` for the search pattern (uses `$A`, `$B` for wildcards, `$$$` for multi-node)
- `-l <lang>` for language (ts, js, py, go, rust, etc.)
- `-r '<replacement>'` for rewrite
- `--json` for structured output when integrating results

Only fall back to the `grep` tool when:
- Searching for non-code content (logs, docs, config values, strings in prose)
- ast-grep doesn't support the language
- You need a simple exact string match in filenames or non-AST text
