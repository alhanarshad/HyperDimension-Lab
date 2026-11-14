$ErrorActionPreference = 'Stop'
$base = Join-Path $PSScriptRoot 'local-build'
$server = Join-Path $base 'server'
New-Item -ItemType Directory -Force -Path "$server\mods", "$server\thunderlands\datapacks", "$base\client\mods", "$base\docs" | Out-Null
$headers = @{'User-Agent'='AZXTY-Thunderlands-Setup/1.0'}
$manifest = New-Object System.Collections.Generic.List[object]
$seen = @{}
function Install-Mod($project, $side, $versionId) {
  $key = "$project/$side"
  if ($seen.ContainsKey($key)) { return }
  $seen[$key]=$true
  if ($versionId) { $v=Invoke-RestMethod "https://api.modrinth.com/v2/version/$versionId" -Headers $headers }
  else {
    $versions=Invoke-RestMethod "https://api.modrinth.com/v2/project/$project/version?game_versions=%5B%221.21.1%22%5D&loaders=%5B%22fabric%22%5D" -Headers $headers
    $v=@($versions | Where-Object {$_.version_type -eq 'release'})[0]
    if (!$v) { throw "No stable Fabric 1.21.1 release: $project" }
  }
  if ($v.game_versions -notcontains '1.21.1' -or $v.loaders -notcontains 'fabric') { throw "Wrong platform: $project" }
  $file=@($v.files | Where-Object primary)[0]
  if (!$file) { $file=$v.files[0] }
  $folder=if ($side -eq 'server') { "$server\mods" } else { "$base\client\mods" }
  $dest=Join-Path $folder $file.filename
  Invoke-WebRequest $file.url -OutFile $dest -Headers $headers -UseBasicParsing
  if ((Get-FileHash $dest -Algorithm SHA512).Hash.ToLower() -ne $file.hashes.sha512) { throw "Hash mismatch: $project" }
  $manifest.Add([pscustomobject]@{project=$project;side=$side;version=$v.version_number;versionId=$v.id;file=$file.filename;sha512=$file.hashes.sha512;url=$file.url;dependencies=$v.dependencies})
  Write-Output "$side : $project $($v.version_number)"
  foreach ($dep in $v.dependencies) {
    if ($dep.dependency_type -eq 'required') {
      if ($dep.project_id) { Install-Mod $dep.project_id $side $dep.version_id }
      elseif ($dep.version_id) { $dv=Invoke-RestMethod "https://api.modrinth.com/v2/version/$($dep.version_id)" -Headers $headers; Install-Mod $dv.project_id $side $dep.version_id }
      else { throw "Unresolved dependency for $project" }
    }
  }
}
foreach ($project in @('fabric-api','lithium','ferrite-core','spark','simple-voice-chat','easyauth')) { Install-Mod $project 'server' $null }
foreach ($project in @('fabric-api','sodium','lithium','ferrite-core','bobby','modmenu','simple-voice-chat')) { Install-Mod $project 'client' $null }
$jjVersions=Get-Content "$PSScriptRoot\jjthunder-versions.json" -Raw | ConvertFrom-Json
$jj=$jjVersions | Where-Object id -eq 'fQwTBBdJ'
$file=$jj.files[0]
$dest=Join-Path "$server\thunderlands\datapacks" $file.filename
Invoke-WebRequest $file.url -OutFile $dest -UseBasicParsing
if ((Get-FileHash $dest -Algorithm SHA512).Hash.ToLower() -ne $file.hashes.sha512) { throw 'JJThunder hash mismatch' }
$manifest.Add([pscustomobject]@{project='jjthunder-to-the-max';side='datapack';version=$jj.version_number;versionId=$jj.id;file=$file.filename;sha512=$file.hashes.sha512;url=$file.url})
$loaders=Invoke-RestMethod 'https://meta.fabricmc.net/v2/versions/loader/1.21.1'
$loader=@($loaders | Where-Object {$_.loader.stable})[0].loader.version
$installers=Invoke-RestMethod 'https://meta.fabricmc.net/v2/versions/installer'
$installer=@($installers | Where-Object stable)[0].version
$launcherUrl="https://meta.fabricmc.net/v2/versions/loader/1.21.1/$loader/$installer/server/jar"
Invoke-WebRequest $launcherUrl -OutFile "$server\fabric-server-launch.jar" -UseBasicParsing
$manifest | ConvertTo-Json -Depth 12 | Set-Content "$base\mod-lock.json" -Encoding UTF8
@{minecraft='1.21.1';loader=$loader;installer=$installer;url=$launcherUrl;sha256=(Get-FileHash "$server\fabric-server-launch.jar" -Algorithm SHA256).Hash;checked='2026-11-07'} | ConvertTo-Json | Set-Content "$base\fabric-lock.json" -Encoding UTF8
Write-Output "Fabric $loader / installer $installer downloaded."
