[CmdletBinding()]
param(
    [ValidateSet('Release','Debug')]
    [string]$Configuration = 'Release',
    [ValidateSet('Ninja','MinGW Makefiles','Visual Studio 17 2022')]
    [string]$Generator = 'Ninja',
    [ValidateSet('x64','Win32')]
    [string]$Architecture = 'x64',
    [string]$VcpkgRoot = '',
    [string]$GameRoot = '',
    [switch]$Launch,
    [switch]$NoAudio,
    [switch]$SafeVideo
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$buildRoot = Join-Path $repoRoot 'build\windows'
$installRoot = Join-Path $buildRoot 'stage'

function Require-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found on PATH. Install CMake and the selected Windows toolchain first."
    }
}

Require-Command 'cmake'
New-Item -ItemType Directory -Force -Path $buildRoot | Out-Null
New-Item -ItemType Directory -Force -Path $installRoot | Out-Null

$cmakeArgs = @(
    '-S', $repoRoot,
    '-B', $buildRoot,
    '-G', $Generator,
    "-DCMAKE_INSTALL_PREFIX=$installRoot",
    '-DBINDIR=bin',
    '-DDATADIR=share/games/flare'
)

if ($Generator -eq 'Visual Studio 17 2022') {
    $cmakeArgs += @('-A', $Architecture)
    $cmakeArgs += @('--fresh')
} else {
    $cmakeArgs += @("-DCMAKE_BUILD_TYPE=$Configuration")
}

if ($VcpkgRoot) {
    $toolchain = Join-Path (Resolve-Path $VcpkgRoot) 'scripts\buildsystems\vcpkg.cmake'
    if (-not (Test-Path -LiteralPath $toolchain)) { throw "vcpkg toolchain not found: $toolchain" }
    $cmakeArgs += "-DCMAKE_TOOLCHAIN_FILE=$toolchain"
}

Write-Host "Configuring Flare Engine from $repoRoot"
& cmake @cmakeArgs
if ($LASTEXITCODE -ne 0) { throw "CMake configure failed ($LASTEXITCODE)." }

$buildArgs = @('--build', $buildRoot, '--config', $Configuration, '--parallel')
Write-Host "Building configuration $Configuration"
& cmake @buildArgs
if ($LASTEXITCODE -ne 0) { throw "Build failed ($LASTEXITCODE)." }

& cmake '--install' $buildRoot '--config' $Configuration
if ($LASTEXITCODE -ne 0) { throw "Install/staging failed ($LASTEXITCODE)." }

$exe = Join-Path $installRoot 'bin\flare.exe'
if (-not (Test-Path -LiteralPath $exe)) {
    $candidate = Get-ChildItem -LiteralPath $buildRoot -Filter 'flare.exe' -Recurse -File | Select-Object -First 1
    if (-not $candidate) { throw "Source build completed but flare.exe was not found." }
    $exe = $candidate.FullName
}

Write-Host "Built executable: $exe"
Write-Host "Engine fallback data: $repoRoot\mods\default"

if ($Launch) {
    if (-not $GameRoot) { throw '-Launch requires -GameRoot pointing to an unmodified flare-game checkout or extracted data root.' }
    $gameRootResolved = (Resolve-Path $GameRoot).Path
    if (-not (Test-Path (Join-Path $gameRootResolved 'mods\mods.txt')) -and -not (Test-Path (Join-Path $gameRootResolved 'mods\default'))) {
        throw "GameRoot does not look like a Flare game-data root: $gameRootResolved"
    }
    $dataPath = $gameRootResolved
    $arguments = @("--data-path=$dataPath", '--renderer=sdl')
    if ($NoAudio) { $arguments += '--no-audio' }
    if ($SafeVideo) { $arguments += '--safe-video' }
    Write-Host "Launching source-built executable with data path $dataPath"
    $proc = Start-Process -FilePath $exe -ArgumentList $arguments -WorkingDirectory (Split-Path $exe) -PassThru
    Write-Host "Started PID $($proc.Id). Close the game normally after confirming the title screen and first map load."
    Wait-Process -Id $proc.Id
}
