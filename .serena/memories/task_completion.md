# Task Completion Checklist

1. Config change → `dotter deploy`, or confirm target is a symlink (already live)
2. Shell change → `fish -n <file>`, then new shell smoke test
3. Lua change → `stylua --check nvim/`; plugin changes: `nvim --headless "+Lazy! sync" +qa`
4. Windows-only change → cannot test from Linux; tell the user
5. No test suite exists — validation is deploy + tool-specific smoke test