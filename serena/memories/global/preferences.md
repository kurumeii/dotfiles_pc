# Global Preferences (cross-project)

- Instruction layering: AGENTS.md is the canonical source of truth, kept fresh via /init. Secondary layers (Serena memories) hold only non-obvious deltas; never duplicate AGENTS.md content; prune memories after any AGENTS.md update.
- Verify-before-trust: after any config/code change, validate syntax and smoke-test the affected tool before claiming done. Changes that cannot be tested from the current machine (e.g. Windows-only edits on Linux) must be flagged explicitly for the user to verify.
- Prefer semantic tooling: when Serena is active, prefer symbolic tools (find_symbol, references, rename) for code questions; use shell only for system lookups (PATH, binaries, packages).