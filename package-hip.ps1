<#
  Build a HIP (ROCm)-accelerated version of llama.cpp on Windows.
  Requires the AMD HIP SDK to be installed and confirmed to support your GPU target.
  Must be run from a "x64 Native Tools Command Prompt for VS" / Developer PowerShell.
  Usage: .\build-hip.ps1 [-Jobs <N>] [-GpuTarget <target>]
#>
param(
    # Defaults to all logical cores. Pass 0 to let cmake/Ninja decide.
    [int]$Jobs = [System.Environment]::ProcessorCount,
    # e.g. gfx1100 (RX 7900XTX/XT), gfx1151 (Ryzen AI Max / Strix Halo)
    [string]$GpuTarget = "gfx1151"
)

$ErrorActionPreference = "Stop"

$BuildDir = Join-Path $PSScriptRoot "build-hip"

if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    throw "cmake not found in PATH. Install CMake and/or run this from a Developer PowerShell for VS 2022."
}

if (-not (Get-Command ninja -ErrorAction SilentlyContinue)) {
    throw "ninja not found in PATH. The HIP build on Windows requires the Ninja generator."
}

if (-not $env:HIP_PATH) {
    throw "HIP_PATH environment variable not set. Install the AMD HIP SDK for Windows first."
}

$env:PATH = "$env:HIP_PATH\bin;$env:PATH"

$configureArgs = @(
    "-S", $PSScriptRoot,
    "-B", $BuildDir,
    "-G", "Ninja",
    "-DCMAKE_BUILD_TYPE=Release",
    "-DGGML_HIP=ON",
    "-DGPU_TARGETS=$GpuTarget",
    "-DCMAKE_C_COMPILER=clang",
    "-DCMAKE_CXX_COMPILER=clang++"
)

cmake @configureArgs
if ($LASTEXITCODE -ne 0) { throw "cmake configure failed" }

$buildArgs = @(
    "--build", $BuildDir
)
if ($Jobs -gt 0) {
    $buildArgs += @("-j", $Jobs)
}

cmake @buildArgs
if ($LASTEXITCODE -ne 0) { throw "cmake build failed" }

$serverExe = Join-Path $BuildDir "bin\llama-server.exe"
Copy-Item $serverExe (Join-Path $BuildDir "bin\aiio-llama-server.exe") -Force

Write-Host "Build finished. Binaries are under: $BuildDir\bin"
