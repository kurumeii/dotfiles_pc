Import-Module Terminal-Icons
# Import-Module posh-git
Import-Module git-aliases -DisableNameChecking
Import-Module DockerCompletion

# enable completion in current shell, use absolute path because PowerShell Core not respect $env:PSModulePath
Import-Module "$($(Get-Item $(Get-Command scoop.ps1).Path).Directory.Parent.FullName)\modules\scoop-completion"


# Setup for different paths
$env:XDG_DATA_HOME = "$env:USERPROFILE\.local\share"
$env:XDG_CONFIG_HOME = "$env:USERPROFILE\.config"
$env:YAZI_CONFiG_HOME= "$env:USERPROFILE\.config\yazi"
$env:BAT_CONFIG_PATH = "$env:USERPROFILE\.config\bat\bat.conf"
$env:BAT_CONFIG_DIR = "$env:USERPROFILE\.config\bat"
$env:EDITOR = "nvim"
# $env:PowerShell_dir = "G:\Other computers\My Computer\Documents\PowerShell"
$env:PowerShell_dir = "$env:USERPROFILE\Documents\PowerShell"
$env:RIPGREP_CONFIG_PATH = "$env:USERPROFILE\.config\rg\.ripgreprc"
$env:TAVILY_API_KEY = "{{TAVILY_API_KEY}}"
$env:CONTEXT_7_API_KEY = "{{CONTEXT_7_API_KEY}}"

(&mise activate pwsh) | Out-String | Invoke-Expression

Set-PSReadLineKeyHandler -Key Tab -ScriptBlock { Invoke-FzfTabCompletion }
Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Invoke-Expression -Command $(gh completion -s powershell | Out-String)
Invoke-Expression -Command $(oh-my-posh init pwsh --config "$env:USERPROFILE\andrew.omp.json")
Invoke-Expression -Command $(zoxide init powershell | Out-String)
Invoke-Expression -Command $(scoop-search --hook)
Invoke-Expression -Command $(ast-grep completions powershell | Out-String)
Invoke-Expression -Command $(bat --completion ps1 | Out-String)
Invoke-Expression -Command $(chezmoi completion powershell | Out-String)
Invoke-Expression -Command $(dotter gen-completions --shell powershell | Out-String)

. "$env:PowerShell_dir/Scripts/omp-completion.ps1"
. "$env:PowerShell_dir/Scripts/winget-completion.ps1"

fastfetch -c examples/8.jsonc

function which ($command)
{
	Get-Command -Name $command -ErrorAction SilentlyContinue |
  Select-Object -ExpandProperty Path -ErrorAction SilentlyContinue
}

function zod
{
	zed.exe --user-data-dir "$env:USERPROFILE\.config\zed" $args
}

