<#
  Build a CUDA-accelerated version of llama.cpp on Windows.
  Requires the NVIDIA CUDA Toolkit to be installed.
  Usage: .\build-cuda.ps1 [-Jobs <N>] [-Architectures <arch-list>]
#>
param(
    [int]$Jobs = 0,
    # e.g. "86" for RTX 30xx, "89" for RTX 40xx. Leave empty to let CMake pick.
    [string]$Architectures = ""
)

$ErrorActionPreference = "Stop"

$BuildDir = Join-Path $PSScriptRoot "build-cuda"

if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    throw "cmake not found in PATH. Install CMake and/or run this from a Developer PowerShell for VS 2022."
}

if (-not $env:CUDA_PATH) {
    throw "CUDA_PATH environment variable not set. Install the NVIDIA CUDA Toolkit first."
}

$configureArgs = @(
    "-S", $PSScriptRoot,
    "-B", $BuildDir,
    "-DCMAKE_BUILD_TYPE=Release",
    "-DGGML_CUDA=ON"
)
if ($Architectures) {
    $configureArgs += "-DCMAKE_CUDA_ARCHITECTURES=$Architectures"
}

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
