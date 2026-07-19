# See powershell/README.md for how this file is structured and how to add a new CLI tool.

# --- Environment ---
$env:XDG_DATA_HOME       = "$env:USERPROFILE\.local\share"
$env:XDG_CONFIG_HOME     = "$env:USERPROFILE\.config"
$env:YAZI_CONFIG_HOME    = "$env:USERPROFILE\.config\yazi"
$env:YAZI_FILE_ONE       = Join-Path (Get-Item (Get-Command git.exe).Path).Directory.Parent.FullName "apps\git\current\usr\bin\file.exe"
$env:BAT_CONFIG_PATH     = "$env:USERPROFILE\.config\bat\bat.conf"
$env:BAT_CONFIG_DIR      = "$env:USERPROFILE\.config\bat"
$env:EDITOR              = "nvim"
# $env:PowerShell_dir    = "G:\Other computers\My Computer\Documents\PowerShell"
$env:PowerShell_dir      = "$env:USERPROFILE\Documents\PowerShell"
$env:RIPGREP_CONFIG_PATH = "$env:USERPROFILE\.config\rg\.ripgreprc"
$env:TAVILY_API_KEY      = "{{TAVILY_API_KEY}}"
$env:CONTEXT_7_API_KEY   = "{{CONTEXT_7_API_KEY}}"
$env:BRAVE_API_KEY       = "{{BRAVE_API_KEY}}"

# --- Cached shell-integration scripts (see README) ---
$script:CompletionCacheMaxAgeDays = 7

function Get-ProfileCompletionCacheFile
{
  Join-Path $env:XDG_DATA_HOME "powershell\completions-cache.ps1"
}

function Update-ProfileCompletionCache
{
  # Self-contained (env vars only, no $script:/$using: references) because
  # this function's body also runs inside Start-Job, a fresh process with no
  # access to this script's variables -- it can't call Get-ProfileCompletionCacheFile
  # or any other sibling function either, only what it defines itself.
  $sources = [ordered]@{
    mise           = { mise activate pwsh }
    gh             = { gh completion -s powershell }
    'oh-my-posh'   = { oh-my-posh init pwsh --config "$env:USERPROFILE\andrew.omp.json" }
    zoxide         = { zoxide init powershell }
    'scoop-search' = { scoop-search --hook }
    'ast-grep'     = { ast-grep completions powershell }
    bat            = { bat --completion ps1 }
    dotter         = { dotter gen-completions --shell powershell }
    'git-flow'     = { git flow completion powershell }
  }

  $chunks = foreach ($name in $sources.Keys) {
    try { & $sources[$name] | Out-String }
    catch { Write-Warning "profile: skipping '$name' completions ($_)" }
  }
  $combined = $chunks -join "`n"

  # `using namespace` must be the first statement(s) in a script, but some
  # tools (e.g. ast-grep) emit one mid-file. Hoist all such lines to the top,
  # deduplicated, so the concatenated result still parses.
  $lines = $combined -split "`r?`n"
  $usingLines = $lines | Where-Object { $_ -match '^\s*using\s+namespace\s+' } | Select-Object -Unique
  $bodyLines  = $lines | Where-Object { $_ -notmatch '^\s*using\s+namespace\s+' }
  $final = (@($usingLines) + @($bodyLines)) -join "`n"

  $cacheFile = Join-Path $env:XDG_DATA_HOME "powershell\completions-cache.ps1"
  $cacheDir = Split-Path $cacheFile -Parent
  if (-not (Test-Path $cacheDir)) {
    New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
  }
  $final | Set-Content -Path $cacheFile -Encoding utf8
}

$profileCacheFile = Get-ProfileCompletionCacheFile
if (-not (Test-Path $profileCacheFile)) {
  Update-ProfileCompletionCache
}
elseif (((Get-Date) - (Get-Item $profileCacheFile).LastWriteTime).TotalDays -gt $script:CompletionCacheMaxAgeDays) {
  Start-Job -ScriptBlock ${function:Update-ProfileCompletionCache} | Out-Null
}
. $profileCacheFile

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

# --- Deferred setup (see README) ---
Register-EngineEvent -SourceIdentifier PowerShell.OnIdle -MaxTriggerCount 1 -Action {
  $modulesToImport = @(
    @{ Name = 'Terminal-Icons' }
    @{ Name = 'git-completion' }
    @{ Name = 'git-aliases'; DisableNameChecking = $true }
    @{ Name = 'DockerCompletion' }
  )
  foreach ($m in $modulesToImport) {
    if ($m.DisableNameChecking) { Import-Module $m.Name -DisableNameChecking }
    else { Import-Module $m.Name }
  }

  # scoop-completion isn't on $env:PSModulePath, so it needs an absolute path
  $scoopModulesDir = Join-Path (Get-Item (Get-Command scoop.ps1).Path).Directory.Parent.FullName "modules\scoop-completion"
  Import-Module $scoopModulesDir

  Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
  Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'

  . "$env:PowerShell_dir/Scripts/omp-completion.ps1"
  . "$env:PowerShell_dir/Scripts/winget-completion.ps1"
} | Out-Null

fastfetch -c examples/8.jsonc

# --- Helper functions ---
function which ($command)
{
  Get-Command -Name $command -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}
