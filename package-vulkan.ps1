<#
  Build a Vulkan-accelerated version of llama.cpp on Windows.
  Usage: .\build-vulkan.ps1 [-Jobs <N>]

    Compatibility:
    - GGML_VULKAN is a vendor-neutral Vulkan backend. The binary is not built
        for the AMD GPU present on the build machine, so it can run on other AMD
        GPUs that provide the required Vulkan features.
    - The target machine needs a current AMD graphics driver with Vulkan 1.2
        support. It does not need the Vulkan SDK; the SDK is needed only to build.
    - Older AMD GPUs or drivers may not support all required Vulkan features.
        Compatibility does not guarantee the same performance across GPU models.
    - This script builds the binaries but does not package or install GPU
        drivers. Distribute the required files from bin\Release together, and
        install the AMD Vulkan driver separately on the target machine.
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

# The output is a binary folder, not a self-contained Vulkan driver package.
Write-Host "Build finished. Binaries are under: $BuildDir\bin\Release (or $BuildDir\bin)"
