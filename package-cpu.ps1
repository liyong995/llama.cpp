<#
  Build a CPU-only version of llama.cpp on Windows.
  Usage: .\build-cpu.ps1 [-Jobs <N>]
#>
param(
    [int]$Jobs = 0
)

$ErrorActionPreference = "Stop"

$BuildDir = Join-Path $PSScriptRoot "build-cpu"

if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    throw "cmake not found in PATH. Install CMake and/or run this from a Developer PowerShell for VS 2022."
}

$configureArgs = @(
    "-S", $PSScriptRoot,
    "-B", $BuildDir,
    "-DCMAKE_BUILD_TYPE=Release"
)

cmake @configureArgs
if ($LASTEXITCODE -ne 0) { throw "cmake configure failed" }

$buildArgs = @(
    "--build", $BuildDir,
    "--config", "Release"
)
if ($Jobs -gt 0) {
    $buildArgs += @("-j", $Jobs)
}

cmake @buildArgs
if ($LASTEXITCODE -ne 0) { throw "cmake build failed" }

$serverExe = Join-Path $BuildDir "bin\Release\llama-server.exe"
Copy-Item $serverExe (Join-Path $BuildDir "bin\Release\aiio-llama-server.exe") -Force

Write-Host "Build finished. Binaries are under: $BuildDir\bin\Release (or $BuildDir\bin)"
