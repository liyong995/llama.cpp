<#
  Build a Vulkan-accelerated version of llama.cpp on Windows.
  Usage: .\build-vulkan.ps1 [-Jobs <N>]
#>
param(
    # Defaults to all logical cores. Pass 0 to let cmake/MSBuild decide.
    [int]$Jobs = [System.Environment]::ProcessorCount
)

$ErrorActionPreference = "Stop"

$BuildDir = Join-Path $PSScriptRoot "build-vulkan"

if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    throw "cmake not found in PATH. Install CMake and/or run this from a Developer PowerShell for VS 2022."
}

if (-not $env:VULKAN_SDK) {
    throw "VULKAN_SDK environment variable not set. Install the Vulkan SDK from https://vulkan.lunarg.com/sdk/home#windows first."
}

$configureArgs = @(
    "-S", $PSScriptRoot,
    "-B", $BuildDir,
    "-DCMAKE_BUILD_TYPE=Release",
    "-DGGML_VULKAN=ON"
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
