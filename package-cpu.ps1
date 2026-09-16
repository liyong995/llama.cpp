<#
  Build a CPU-only version of llama.cpp on Windows.
  Usage: .\build-cpu.ps1 [-Jobs <N>]

    Compatibility:
    - GGML_NATIVE=OFF prevents the build from targeting the CPU used to build
        the package, so the binary is suitable for other compatible x64 CPUs.
    - This is not a guarantee for every CPU. The target must support the
        instruction sets used by the selected CPU backend and use the same Windows
        architecture. Very old CPUs may still be incompatible.
    - Disabling GGML_NATIVE improves portability but can reduce performance
        compared with a build optimized for one specific CPU model.
    - For a package covering more CPU instruction-set variants, use
        GGML_BACKEND_DL=ON and GGML_CPU_ALL_VARIANTS=ON. That produces a more
        flexible package but uses runtime backend selection and a more complex
        output layout.
#>
param(
    # Defaults to all logical cores. Pass 0 to let cmake/MSBuild decide.
    [int]$Jobs = [System.Environment]::ProcessorCount
)

$ErrorActionPreference = "Stop"

$BuildDir = Join-Path $PSScriptRoot "build-cpu"

if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    throw "cmake not found in PATH. Install CMake and/or run this from a Developer PowerShell for VS 2022."
}

$configureArgs = @(
    "-S", $PSScriptRoot,
    "-B", $BuildDir,
    "-DCMAKE_BUILD_TYPE=Release",
    "-DGGML_NATIVE=OFF"
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
