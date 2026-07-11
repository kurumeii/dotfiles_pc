# PowerShell profile

`Microsoft.PowerShell_profile.ps1` is hardlinked into `Documents\PowerShell\` (via `dotter`),
so editing the file here takes effect immediately without redeploying.

## Why it's structured this way

Naively, a profile that calls `Invoke-Expression (tool init)` for every CLI tool and
`Import-Module` for every completion module adds up fast — each is a subprocess spawn or a
module load, and they all block the prompt from appearing. This profile avoids that with two
techniques:

1. **Cache generated shell-integration scripts.** Tools like `oh-my-posh`, `zoxide`, `gh`, etc.
   each print a chunk of PowerShell when invoked (e.g. `oh-my-posh init pwsh`). That output
   rarely changes between sessions, so instead of running all of them on every startup, they're
   run once and the combined output is cached to
   `$env:XDG_DATA_HOME\powershell\completions-cache.ps1`, which is just dot-sourced afterwards.
   The cache auto-refreshes in the background (`Start-Job`, non-blocking) once it's more than
   `$CompletionCacheMaxAgeDays` old.

2. **Defer module imports until after the prompt renders.** Modules like `Terminal-Icons` or
   `git-completion` aren't needed to *show* a prompt — only to enhance it once it's there. They're
   imported inside a `Register-EngineEvent -SourceIdentifier PowerShell.OnIdle` handler, which
   fires once, right after the first prompt is drawn, instead of blocking it.

Together these cut time-to-first-prompt from ~4.3s to well under 1s.

## Adding a new CLI tool

**If the tool just needs its init/completion script generated once and cached** (the common
case — most `<tool> init powershell` / `<tool> completion powershell` style commands):

Add one entry to the `$sources` ordered dictionary inside `Update-ProfileCompletionCache`:

```powershell
$sources = [ordered]@{
  ...
  mytool = { mytool init powershell }
}
```

Then refresh the cache immediately (don't wait for the 7-day auto-refresh):

```powershell
Update-ProfileCompletionCache
```

If the tool's generated script fails for any reason (not installed, errors out), it's skipped
with a warning rather than breaking the whole cache — safe to add speculatively.

**If the tool ships a real PowerShell module** (`Import-Module SomeModule`) rather than an
init/completion command:

Add it to the `$modulesToImport` array inside the `PowerShell.OnIdle` handler:

```powershell
$modulesToImport = @(
  ...
  @{ Name = 'SomeModule' }
  # add DisableNameChecking = $true if the module warns about unapproved verbs
)
```

Modules don't need the cache — importing a module is just reading it from disk, so there's no
process-spawn cost to cache; deferring it past the first prompt is what saves the time.

## Useful commands

- `Update-ProfileCompletionCache` — force-regenerate the completions cache now (e.g. right after
  upgrading one of the cached tools, so you don't wait up to 7 days for the background refresh).
- `Get-ProfileCompletionCacheFile` — print the path to the current cache file.
