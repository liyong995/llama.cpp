<#
  Build a CUDA-accelerated version of llama.cpp on Windows.
  Requires the NVIDIA CUDA Toolkit to be installed.
  Usage: .\build-cuda.ps1 [-Jobs <N>] [-Architectures <arch-list>]
  By default builds only for the architecture of the GPU(s) detected via nvidia-smi
  and uses all logical CPU cores, which is much faster than building every architecture.
#>
param(
    # Defaults to all logical cores. Pass 0 to let cmake/MSBuild decide.
    [int]$Jobs = [System.Environment]::ProcessorCount,
    # e.g. "86" for RTX 30xx, "89" for RTX 40xx. Leave empty to auto-detect via nvidia-smi.
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

if (-not $Architectures -and (Get-Command nvidia-smi -ErrorAction SilentlyContinue)) {
    $caps = & nvidia-smi --query-gpu=compute_cap --format=csv,noheader 2>$null | Select-Object -Unique
    if ($caps) {
        $Architectures = ($caps | ForEach-Object { $_.Trim() -replace '\.', '' }) -join ';'
        Write-Host "Detected GPU compute capability, building only for: $Architectures"
    }
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
