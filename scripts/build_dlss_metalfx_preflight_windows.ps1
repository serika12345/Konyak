[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
  throw "The DLSS MetalFX preflight fixture must be built on Windows."
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$fixtureRoot = Join-Path $repoRoot "tests/fixtures/windows/dlss_metalfx_preflight"
$artifactRoot = Join-Path $repoRoot ".dart_tool/konyak/windows-dlss-metalfx-preflight"
$preset = "windows-msvc-v143-x64"
$buildPreset = "windows-msvc-v143-x64-release"

$vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio/Installer/vswhere.exe"
if (-not (Test-Path $vswhere)) {
  throw "Missing vswhere.exe at $vswhere"
}

$visualStudioPath = & $vswhere `
  -products * `
  -version "[17.0,18.0)" `
  -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
  -latest `
  -property installationPath
if (-not $visualStudioPath) {
  throw "Visual Studio 2022 with the MSVC x64 toolchain was not found."
}

$cmake = Get-Command cmake -ErrorAction Stop
Write-Host "Using Visual Studio: $visualStudioPath"
Write-Host "Using CMake: $($cmake.Source)"
& $cmake.Source --version

Push-Location $fixtureRoot
try {
  & $cmake.Source --preset $preset
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }

  & $cmake.Source --build --preset $buildPreset
  if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
  }
} finally {
  Pop-Location
}

$builtExe = Join-Path $fixtureRoot "out/build/$preset/Release/konyak_dlss_metalfx_preflight.exe"
if (-not (Test-Path $builtExe)) {
  throw "Build completed without producing $builtExe"
}

New-Item -ItemType Directory -Force -Path $artifactRoot | Out-Null
$artifact = Join-Path $artifactRoot "konyak_dlss_metalfx_preflight.exe"
Copy-Item -Force $builtExe $artifact
Write-Output $artifact
