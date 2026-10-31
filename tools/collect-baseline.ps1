# Read-only Windows ADB baseline. Output goes under backup/ (git-ignored) by default.
# Use exact values just read from this TV; never reuse another TV's identity.
param(
    [Parameter(Mandatory = $true)][string]$Device,
    [Parameter(Mandatory = $true)][string]$ExpectedModel,
    [Parameter(Mandatory = $true)][string]$ExpectedBuild,
    [string]$ModelProperty = 'ro.product.oemmodel',
    [string]$BackupRoot = (Join-Path (Split-Path -Parent $PSScriptRoot) 'backup'),
    [string]$AdbPath = 'adb'
)

$ErrorActionPreference = 'Stop'
if ($ModelProperty -notmatch '^ro\.[a-zA-Z0-9_.]+$') { throw 'Invalid model property.' }
$adb = (Get-Command $AdbPath -ErrorAction Stop).Source
function Read-Adb([string[]]$Arguments) {
    $result = @(& $adb -s $Device @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "ADB command failed: $($Arguments -join ' '): $result" }
    return $result
}

$state = (Read-Adb @('get-state') | Out-String).Trim()
$model = (Read-Adb @('shell', 'getprop', $ModelProperty) | Out-String).Trim()
$build = (Read-Adb @('shell', 'getprop', 'ro.build.version.name') | Out-String).Trim()
if ($state -ne 'device' -or $model -ne $ExpectedModel -or $build -ne $ExpectedBuild) {
    throw "Device identity mismatch. state=$state model=$model build=$build; no backup or TV change made."
}

$stamp = Get-Date -Format 'yyyy-MM-dd_HHmmss'
$BackupRoot = [IO.Path]::GetFullPath($BackupRoot)
New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
$backup = Join-Path $BackupRoot $stamp
if (Test-Path -LiteralPath $backup) { throw "Backup destination already exists: $backup" }
New-Item -ItemType Directory -Path $backup | Out-Null
if ($IsWindows) {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
    $grant = '{0}:(OI)(CI)F' -f $identity
    & icacls.exe $backup /inheritance:r /grant:r $grant 'SYSTEM:(OI)(CI)F' | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Could not restrict backup directory access.' }
}

[ordered]@{
    captured_at = (Get-Date).ToString('o')
    device = $Device
    model_property = $ModelProperty
    model = $model
    build = $build
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $backup 'manifest.json') -Encoding utf8

$collections = [ordered]@{
    'packages-all.txt' = @('shell','pm','list','packages')
    'packages-system.txt' = @('shell','pm','list','packages','-s')
    'packages-third-party.txt' = @('shell','pm','list','packages','-3')
    'packages-enabled.txt' = @('shell','pm','list','packages','-e')
    'packages-disabled.txt' = @('shell','pm','list','packages','-d')
    'getprop.txt' = @('shell','getprop')
    'settings-system.txt' = @('shell','settings','list','system')
    'settings-secure.txt' = @('shell','settings','list','secure')
    'settings-global.txt' = @('shell','settings','list','global')
    'home-resolve.txt' = @('shell','cmd','package','resolve-activity','-a','android.intent.action.MAIN','-c','android.intent.category.HOME')
    'accessibility.txt' = @('shell','dumpsys','accessibility')
    'tv-inputs.txt' = @('shell','dumpsys','tv_input')
    'meminfo.txt' = @('shell','cat','/proc/meminfo')
    'cpuinfo.txt' = @('shell','dumpsys','cpuinfo')
    'storage.txt' = @('shell','df','-k','/data')
    'connectivity.txt' = @('shell','dumpsys','connectivity')
    'wifi.txt' = @('shell','dumpsys','wifi')
}
foreach ($item in $collections.GetEnumerator()) {
    Read-Adb $item.Value | Set-Content -LiteralPath (Join-Path $backup $item.Key) -Encoding utf8
}

$shot = Join-Path $backup 'initial-screen.png'
& $adb -s $Device exec-out screencap -p > $shot
if ($LASTEXITCODE -ne 0) { throw 'Screenshot capture failed.' }
$bytes = [IO.File]::ReadAllBytes($shot)
if ($bytes.Length -lt 8 -or [Text.Encoding]::ASCII.GetString($bytes, 1, 3) -ne 'PNG') {
    throw 'Screenshot did not have a PNG header.'
}
Write-Output "Private baseline saved: $backup"
