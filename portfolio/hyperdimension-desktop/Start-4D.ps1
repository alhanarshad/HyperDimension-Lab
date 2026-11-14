param([switch]$CheckOnly)
$ErrorActionPreference = 'Stop'

# All content stays on this laptop. No server, account, or download is needed.
$appFile = Join-Path $PSScriptRoot 'index.html'
if (-not (Test-Path -LiteralPath $appFile -PathType Leaf)) {
    throw 'index.html is missing. Extract the complete 4D-Desktop folder before starting the app.'
}
$appUrl = ([System.Uri](Resolve-Path -LiteralPath $appFile).Path).AbsoluteUri
$edgeCandidates = @(
    (Join-Path ${env:ProgramFiles(x86)} 'Microsoft\Edge\Application\msedge.exe'),
    (Join-Path $env:ProgramFiles 'Microsoft\Edge\Application\msedge.exe'),
    (Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\Application\msedge.exe')
)
$edgePath = $edgeCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1
if ($CheckOnly) {
    [pscustomobject]@{ AppExists = $true; AppUrl = $appUrl; EdgeFound = [bool]$edgePath; EdgePath = $edgePath } | ConvertTo-Json -Compress
    return
}
if ($edgePath) {
    # A standalone app window backed by the Edge browser already on Windows.
    Start-Process -FilePath $edgePath -ArgumentList @("--app=$appUrl", '--window-size=1440,960')
} else {
    Write-Host 'Microsoft Edge was not found. Opening the offline app in your default browser.'
    Start-Process -FilePath $appFile
}
