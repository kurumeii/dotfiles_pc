# Serena (MCP) — auto-load

Serena's MCP server is started automatically with `--context ide --project-from-cwd`.
Its instructions are NOT injected into your system prompt; they must be fetched once per session.

- At the start of every session, before answering anything or using any other tool, load the Serena manual by calling its `initial_instructions` tool (in Code Mode: `tools.serena.initial_instructions()`, otherwise the serena `initial_instructions` tool) and follow it.
- For ALL work in this codebase — including questions like "where is X defined" — prefer Serena's tools (symbol overview, `find_symbol`, pattern search) over `read`/`glob`/`grep`. Only fall back to built-in tools for non-code files or when Serena cannot answer.
- Serena sessions: keep memories in sync per its manual; the deployed memories live in `~/.serena/memories`.
- A pattern search that returns empty is NOT evidence of absence. Before falling back to shell (grep/rg), verify the call itself: `search_for_pattern`'s 2nd positional argument is `context_lines_before` (an int), not a path — restrict scope with `relative_path=` or `paths_include_glob=` instead. A mis-argued call returns `{}` silently. Shell is a last resort: only after a correctly formed search returned empty, and state in the reply why empty was plausible.
