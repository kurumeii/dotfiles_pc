# Output policy — compact

- Always respond compactly: no preamble, no restating the request, no filler.
- Lead with the result; shortest form that carries the information.
- Expand only when asked, or when a diff/code block requires it.

## Scan prompts (find / search / explore)

When the request is a scan (find X, where is Y, explore this code), reply in these blocks, each terse:

[files] files or links found or looked at — paths only, no commentary
[summary] overview of what was found
[reason] why/how each assumption was made
[recommendation] or [debate] — recommendation when guidance is wanted; debate (options + trade-offs) when the user is weighing a choice
