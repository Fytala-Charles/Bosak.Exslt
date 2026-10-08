#Requires -Version 7
<#
.SYNOPSIS
    Configuration check for the Bosak.Exslt training environment (session 00).

.DESCRIPTION
    Verifies the toolchain the training curriculum assumes:
      1. .NET SDK 10.0+ on PATH (runs the test harness)
      2. VS Code 'code' CLI on PATH
      3. Bosak XPath / XSLT extension installed (fytala.vscode-bosak)
      4. Node.js 18+ (warning only — needed solely to build the extension from source)
      5. With -RunTests: runs the training harness end-to-end as final proof.

.PARAMETER RunTests
    Additionally run 'dotnet test training/TrainingTests/TrainingTests.csproj'
    from the repository root and report the outcome.

.EXAMPLE
    pwsh training/00-setup/check-setup.ps1 -RunTests
#>
[CmdletBinding()]
param(
    [switch]$RunTests
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:pass = 0
$script:fail = 0
$script:warn = 0

function Write-Result([string]$Status, [string]$Message) {
    switch ($Status) {
        'Pass' { $script:pass++; Write-Host "  [PASS] $Message" -ForegroundColor Green }
        'Fail' { $script:fail++; Write-Host "  [FAIL] $Message" -ForegroundColor Red }
        'Warn' { $script:warn++; Write-Host "  [WARN] $Message" -ForegroundColor Yellow }
        'Info' { Write-Host "  [INFO] $Message" -ForegroundColor Cyan }
    }
}

Write-Host ""
Write-Host "Bosak.Exslt training environment check" -ForegroundColor Cyan
Write-Host ""

# ---------------------------------------------------------------------------
Write-Host "1. .NET SDK" -ForegroundColor Cyan

$dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
if (-not $dotnet) {
    Write-Result Fail "dotnet CLI not found on PATH — install the .NET 10 SDK (https://dotnet.microsoft.com/download)"
}
else {
    $rawVersion = (& dotnet --version | Select-Object -First 1).Trim()
    $sdkVersion = $null
    try {
        $sdkVersion = [version]($rawVersion -replace '-.*$', '')
    }
    catch {
        Write-Result Fail "could not parse 'dotnet --version' output: $rawVersion"
    }
    if ($sdkVersion) {
        if ($sdkVersion.Major -ge 10) {
            Write-Result Pass ".NET SDK $rawVersion (10+ required for the training harness)"
        }
        else {
            Write-Result Fail ".NET SDK $rawVersion is too old — the training harness needs 10.0+ (https://dotnet.microsoft.com/download)"
        }
    }
}

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "2. VS Code CLI" -ForegroundColor Cyan

$code = Get-Command code -ErrorAction SilentlyContinue
if (-not $code) {
    Write-Result Fail "VS Code 'code' command not found on PATH — reinstall VS Code with the 'Add to PATH' option, or add it manually"
}
else {
    Write-Result Pass "code CLI found: $($code.Source)"
}

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "3. Bosak XPath / XSLT extension" -ForegroundColor Cyan

if (-not $code) {
    Write-Result Fail "extension cannot be checked without the code CLI (see check 2)"
}
else {
    $installed = @(& code --list-extensions 2>$null | ForEach-Object { $_.Trim() })
    if ($installed -contains 'fytala.vscode-bosak') {
        Write-Result Pass "fytala.vscode-bosak installed"
    }
    else {
        Write-Result Fail "fytala.vscode-bosak not installed — Extensions Marketplace: 'Bosak XPath / XSLT' (publisher: fytala); see training/00-setup/README.md section 3"
    }
}

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "4. Node.js (optional — only for building the extension from source)" -ForegroundColor Cyan

$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    Write-Result Warn "node not found on PATH — only needed if you build the Bosak extension yourself (session 00 section 3, option B)"
}
else {
    $nodeVersion = $null
    try {
        $nodeVersion = [version]((& node --version) -replace '^v', '' -replace '-.*$', '')
    }
    catch {
        Write-Result Warn "could not parse 'node --version' output"
    }
    if ($nodeVersion) {
        if ($nodeVersion.Major -ge 18) {
            Write-Result Pass "Node.js $($nodeVersion) (18+ only needed to build the extension from source)"
        }
        else {
            Write-Result Warn "Node.js $($nodeVersion) is older than 18 — upgrade if you build the extension from source"
        }
    }
}

# ---------------------------------------------------------------------------
if ($RunTests) {
    Write-Host ""
    Write-Host "5. End-to-end: training harness (dotnet test)" -ForegroundColor Cyan

    $repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    Push-Location $repoRoot
    try {
        & dotnet test training/TrainingTests/TrainingTests.csproj 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Result Pass "training harness green (Solution_matches_golden and Starter_differs_from_golden pass)"
        }
        else {
            Write-Result Fail "training harness did not pass — run 'dotnet test training/TrainingTests/TrainingTests.csproj' for details"
        }
    }
    finally {
        Pop-Location
    }
}

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "  Passed:   $pass"
Write-Host "  Failed:   $fail"
Write-Host "  Warnings: $warn"

if ($fail -gt 0) {
    Write-Host ""
    Write-Host "SETUP INCOMPLETE — fix the FAIL lines above (see training/00-setup/README.md)" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "SETUP OK — you are ready for session 01" -ForegroundColor Green
exit 0
