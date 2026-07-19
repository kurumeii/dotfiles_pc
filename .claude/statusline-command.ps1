# ============================================================================
# Claude Code statusLine
#
# Mirrors the oh-my-posh theme at C:\Users\hoanganh\andrew.omp.json: plain
# text labels/separators throughout, except the git changed/staged counts,
# which reuse that theme's nerd-font icons ( / ).
#
# Segments (left to right):
#   username        (#E36464)
#   current folder  (#56B6C2)
#   git branch/status, incl. ahead/behind + changed/staged counts (#D4AAFC)
#   node version, only shown in a Node project                    (#98C379)
#   current model                                                 (#DCB977)
#
# Note: the original theme's "status" segment reflects the exit code of the
# last command run in an interactive PowerShell session. Claude Code invokes
# this script fresh on every render with no access to a prior shell command's
# exit code, so there is no faithful equivalent here and the segment is
# omitted.
# ============================================================================

$ErrorActionPreference = 'SilentlyContinue'

$stdin = [Console]::In.ReadToEnd()
$data = $null
if ($stdin) {
  try { $data = $stdin | ConvertFrom-Json } catch { $data = $null }
}

function Get-AnsiColor([string]$hex) {
  $r = [Convert]::ToInt32($hex.Substring(1, 2), 16)
  $g = [Convert]::ToInt32($hex.Substring(3, 2), 16)
  $b = [Convert]::ToInt32($hex.Substring(5, 2), 16)
  $e = [char]27
  return "$e[38;2;$r;$g;${b}m"
}

$e = [char]27
$reset = "$e[0m"
$white = "$e[38;2;255;255;255m"
$cUser = Get-AnsiColor '#E36464'
$cPath = Get-AnsiColor '#56B6C2'
$cGit = Get-AnsiColor '#D4AAFC'
$cNode = Get-AnsiColor '#98C379'
$cModel = Get-AnsiColor '#DCB977'

$cwd = $null
if ($data -and $data.workspace -and $data.workspace.current_dir) {
  $cwd = $data.workspace.current_dir
}
if (-not $cwd) { $cwd = (Get-Location).Path }

$segments = New-Object System.Collections.Generic.List[string]

# --- username -----------------------------------------------------------
$username = $env:USERNAME
if (-not $username) { $username = (whoami) }
$segments.Add("$cUser@$username$reset")

# --- current folder (folder style = last path segment only) ------------
$folder = Split-Path -Path $cwd -Leaf
if (-not $folder) { $folder = $cwd }
$segments.Add("$cPath$folder$reset")

# --- git branch/status ---------------------------------------------------
git -C $cwd --no-optional-locks rev-parse --is-inside-work-tree 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
  $branch = (git -C $cwd --no-optional-locks branch --show-current 2>$null)
  if (-not $branch) {
    $branch = (git -C $cwd --no-optional-locks rev-parse --short HEAD 2>$null)
  }

  $staged = 0
  $unstaged = 0
  $statusLines = git -C $cwd --no-optional-locks status --porcelain=v1 2>$null
  foreach ($line in $statusLines) {
    if ($line.Length -ge 2) {
      if ($line[0] -ne ' ' -and $line[0] -ne '?') { $staged++ }
      if ($line[1] -ne ' ' -and $line[1] -ne '?') { $unstaged++ }
    }
  }

  $ahead = (git -C $cwd --no-optional-locks rev-list --count '@{u}..HEAD' 2>$null)
  $behind = (git -C $cwd --no-optional-locks rev-list --count 'HEAD..@{u}' 2>$null)

  $gitStr = "$branch"
  if ($ahead -and [int]$ahead -gt 0) { $gitStr += " +$ahead" }
  if ($behind -and [int]$behind -gt 0) { $gitStr += " -$behind" }
  if ($unstaged -gt 0) { $gitStr += " `u{f044} $unstaged" }
  if ($staged -gt 0) { $gitStr += " `u{f046} $staged" }

  $segments.Add("${white}on $reset$cGit$gitStr$reset")
}

# --- node version (only in a node project) --------------------------------
$isNodeProject = (Test-Path (Join-Path $cwd 'package.json')) -or
  (Test-Path (Join-Path $cwd '.nvmrc')) -or
  (Test-Path (Join-Path $cwd '.node-version'))
if ($isNodeProject) {
  $nodeVersion = (& node -v 2>$null)
  if ($nodeVersion) {
    $segments.Add("${white}via $reset${cNode}node $nodeVersion$reset")
  }
}

# --- current model --------------------------------------------------------
if ($data -and $data.model -and $data.model.display_name) {
  $segments.Add("${white}via $reset${cModel}$($data.model.display_name)$reset")
}

# --- ponytail mode (flag file written by the ponytail plugin's hooks) -----
$ponytailFlag = Join-Path $(if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME ".claude" }) ".ponytail-active"
if (Test-Path $ponytailFlag) {
  $ponytailMode = (Get-Content $ponytailFlag -ErrorAction SilentlyContinue | Select-Object -First 1)
  $ponytailColor = if ($ponytailMode -eq 'ultra') { "$e[38;5;173m" } else { "$e[38;5;108m" }
  $ponytailLabel = if ([string]::IsNullOrEmpty($ponytailMode) -or $ponytailMode -eq 'full') { 'PONYTAIL' } else { "PONYTAIL:$($ponytailMode.ToUpperInvariant())" }
  $segments.Add("$ponytailColor[$ponytailLabel]$reset")
}

Write-Output ($segments -join " ")
