<#
  Package CPU, CUDA, and Vulkan builds into one directory.
  Usage: .\package-cpu-cuda-vulkan.ps1 [-Build] [-Jobs <N>] [-Architectures <arch-list>] [-OutputDir <path>]
#>
param(
    [switch]$Build,
    [int]$Jobs = 0,
    [string]$Architectures = "",
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

function Invoke-BuildScript {
    param(
        [string]$ScriptPath,
        [string[]]$Arguments = @()
    )

    & $ScriptPath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Build script failed: $ScriptPath"
    }
}

function Resolve-BinaryDir {
    param([string]$BuildDir)

    $candidates = @(
        (Join-Path $BuildDir "bin\Release"),
        (Join-Path $BuildDir "bin")
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate -PathType Container) {
            return $candidate
        }
    }

    throw "Build output directory not found: $BuildDir\bin\Release or $BuildDir\bin"
}

if ($Build) {
    $jobsArguments = @()
    if ($Jobs -gt 0) {
        $jobsArguments += @("-Jobs", $Jobs)
    }

    Invoke-BuildScript (Join-Path $PSScriptRoot "package-cpu.ps1") $jobsArguments

    $cudaArguments = @($jobsArguments)
    if ($Architectures) {
        $cudaArguments += @("-Architectures", $Architectures)
    }
    Invoke-BuildScript (Join-Path $PSScriptRoot "package-cuda.ps1") $cudaArguments
    Invoke-BuildScript (Join-Path $PSScriptRoot "package-vulkan.ps1") $jobsArguments
}

$outputRoot = if ($OutputDir) {
    $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDir)
} else {
    Join-Path $PSScriptRoot "package-cpu-cuda-vulkan"
}

if (Test-Path $outputRoot) {
    Remove-Item $outputRoot -Recurse -Force
}
New-Item $outputRoot -ItemType Directory -Force | Out-Null

$backends = @(
    @{ Name = "cpu"; BuildDir = (Join-Path $PSScriptRoot "build-cpu") },
    @{ Name = "cuda"; BuildDir = (Join-Path $PSScriptRoot "build-cuda") },
    @{ Name = "vulkan"; BuildDir = (Join-Path $PSScriptRoot "build-vulkan") }
)

foreach ($backend in $backends) {
    $sourceDir = Resolve-BinaryDir $backend.BuildDir
    $destinationDir = Join-Path $outputRoot $backend.Name
    New-Item $destinationDir -ItemType Directory -Force | Out-Null
    Copy-Item (Join-Path $sourceDir "*") $destinationDir -Recurse -Force
    Write-Host "Packaged $($backend.Name): $sourceDir -> $destinationDir"
}

Write-Host "Package finished: $outputRoot"