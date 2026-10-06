#Requires -Version 7
<#
.SYNOPSIS
    Documentation hygiene checker for the Bosak.Exslt repository.

.DESCRIPTION
    Verifies the house documentation conventions:
      1. Required files exist (this repository's actual names — LICENSE, not LICENSE.md).
      2. Every src/**/*.xsl file is well-formed XML and carries the
         AUTHOR / PURPOSE / LICENSE header markers.
      3. Date freshness ("Last updated: YYYY-MM-DD") on the living documents.
      4. Cross-references in Markdown files resolve to real files.
      5. Every golden case has its required artifacts and a valid meta.json.
      6. Fytala Docs Kit branding: .fytala-docs.json present, kit asset integrity
         (SHA-256 against docs-kit/manifest.json), branded banner + (c) Fytala
         footer on canonical documents, and the About FYTALA statement in README.md.

.PARAMETER ProjectPath
    Repository root to check. Defaults to the current directory.

.PARAMETER Strict
    Treat warnings as failures.

.EXAMPLE
    pwsh tools/check-docs.ps1 -ProjectPath .
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$ProjectPath = '.',

    [switch]$Strict
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = (Resolve-Path $ProjectPath).Path
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
Write-Host "Bosak.Exslt documentation hygiene check" -ForegroundColor Cyan
Write-Host "Project: $root"
Write-Host ""

# ---------------------------------------------------------------------------
Write-Host "1. Required files" -ForegroundColor Cyan

$requiredFiles = @(
    'README.md',
    'AGENTS.md',
    'ROADMAP.md',
    'LICENSE',
    'Directory.Build.props',
    '.gitignore',
    '.editorconfig',
    'tools/check-docs.ps1',
    'docs/ARCHITECTURE.md',
    'docs/COMPATIBILITY.md',
    'docs/FEATURE_REQUESTS.md',
    'docs/AGENT_HANDOVER.md',
    'docs/DOCUMENTATION_STYLE_GUIDE.md',
    'docs/ADR-000-TEMPLATE.md',
    'docs/XSLT_STYLE_GUIDE.md',
    'tests/ATTRIBUTION.md',
    'tests/Bosak.Exslt.Tests/README.md',
    '.fytala-docs.json',
    'docs-kit/manifest.json',
    'assets/logos/fytala-logo-color-dark.svg',
    'assets/logos/fytala-logo-color-light.svg',
    'assets/css/fytala-brand.css',
    'assets/css/fytala-markdown.css'
)

foreach ($file in $requiredFiles) {
    if (Test-Path (Join-Path $root $file)) {
        Write-Result Pass "present: $file"
    }
    else {
        Write-Result Fail "missing required file: $file"
    }
}

# ADRs beyond the template must be numbered sequentially, never reused.
$adrs = Get-ChildItem -Path (Join-Path $root 'docs') -Filter 'ADR-*.md' -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne 'ADR-000-TEMPLATE.md' } |
    Sort-Object Name
if ($adrs) {
    foreach ($adr in $adrs) {
        if ($adr.Name -match '^ADR-(\d{3})-') {
            Write-Result Pass "ADR present: docs/$($adr.Name)"
        }
        else {
            Write-Result Fail "ADR name does not match ADR-NNN-<slug>.md: docs/$($adr.Name)"
        }
    }
}
else {
    Write-Result Warn 'no ADRs found beyond the template'
}

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "2. XSLT module files (well-formed XML + header markers)" -ForegroundColor Cyan

$xslFiles = Get-ChildItem -Path (Join-Path $root 'src') -Filter '*.xsl' -Recurse -File -ErrorAction SilentlyContinue
if (-not $xslFiles) {
    Write-Result Fail 'no .xsl files found under src/'
}

foreach ($file in $xslFiles) {
    $relative = "src/$($file.Name)"
    $text = $null
    try {
        $text = Get-Content -Path $file.FullName -Raw
        [void][xml]$text
        Write-Result Pass "well-formed XML: $relative"
    }
    catch {
        Write-Result Fail "not well-formed XML: $relative — $($_.Exception.Message)"
        continue
    }

    $header = $text.Substring(0, [Math]::Min(2000, $text.Length))
    foreach ($marker in @('AUTHOR', 'PURPOSE', 'LICENSE')) {
        if ($header -match $marker) {
            Write-Result Pass "header marker '$marker': $relative"
        }
        else {
            Write-Result Fail "header marker '$marker' missing: $relative"
        }
    }
}

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "3. Date freshness (Last updated: YYYY-MM-DD)" -ForegroundColor Cyan

$datedFiles = @(
    'docs/FEATURE_REQUESTS.md',
    'docs/AGENT_HANDOVER.md',
    'ROADMAP.md'
)

foreach ($file in $datedFiles) {
    $path = Join-Path $root $file
    if (-not (Test-Path $path)) {
        Write-Result Fail "missing: $file"
        continue
    }
    $text = Get-Content -Path $path -Raw
    $matches = [regex]::Matches($text, '[Uu]pdated:\s*(\d{4}-\d{2}-\d{2})')
    if ($matches.Count -eq 0) {
        Write-Result Fail "no 'Last updated: YYYY-MM-DD' marker: $file"
        continue
    }
    $latest = ($matches | ForEach-Object { [datetime]::ParseExact($_.Groups[1].Value, 'yyyy-MM-dd', $null) } |
        Sort-Object -Descending | Select-Object -First 1)
    $age = (Get-Date) - $latest
    if ($age.Days -gt 90) {
        Write-Result Warn "$file last updated $($latest.ToString('yyyy-MM-dd')) — older than 90 days"
    }
    else {
        Write-Result Pass "fresh ($($latest.ToString('yyyy-MM-dd'))): $file"
    }
}

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "4. Markdown cross-references resolve" -ForegroundColor Cyan

$mdFiles = Get-ChildItem -Path $root -Filter '*.md' -Recurse -File |
    Where-Object { $_.FullName -notmatch '[\\/]\.(git)[\\/]' -and
                   $_.FullName -notmatch '[\\/](bin|obj)[\\/]' }

# Kit-managed Markdown files (hash-pinned in docs-kit/manifest.json) are canonical
# kit content; their references are the kit's own contract, verified by SHA-256 in
# section 6, not by this repository's link inventory.
$kitManagedMd = @()
$manifestPathForRefs = Join-Path $root 'docs-kit/manifest.json'
if (Test-Path $manifestPathForRefs) {
    try {
        $kitManagedMd = @((Get-Content -Path $manifestPathForRefs -Raw | ConvertFrom-Json).files |
            Where-Object { $_.destination -like '*.md' } |
            ForEach-Object { $_.destination })
    }
    catch {
        # Manifest parse failures are reported in section 6.
    }
}

$broken = 0
foreach ($file in $mdFiles) {
    $relativeMd = $file.FullName.Substring($root.Length + 1) -replace '\\', '/'
    if ($kitManagedMd -contains $relativeMd) {
        Write-Result Info "cross-references not checked (kit-managed, hash-pinned): $relativeMd"
        continue
    }
    $text = Get-Content -Path $file.FullName -Raw
    $targets = [System.Collections.Generic.List[string]]::new()

    # Repo-relative references such as docs/COMPATIBILITY.md (plain text or link targets).
    foreach ($match in [regex]::Matches($text, '(?:\]\()?(docs/[A-Za-z0-9._/-]+\.md)')) {
        $targets.Add($match.Groups[1].Value)
    }
    # Sibling/parent links:](./NAME.md) or](../NAME.md) — resolve relative to the file.
    foreach ($match in [regex]::Matches($text, '\]\((\.{1,2}/[A-Za-z0-9._/-]+\.md)(?:#[^)]*)?\)')) {
        $targets.Add((Join-Path $file.DirectoryName $match.Groups[1].Value))
    }

    foreach ($target in $targets) {
        if ($target -notmatch '^[A-Za-z]:[\\/]' -and $target -notmatch '^\.[\\/]') {
            $target = Join-Path $root $target
        }
        if (Test-Path $target) {
            Write-Result Pass "reference resolves: $(Resolve-Path $target | ForEach-Object { $_.Path.Substring($root.Length + 1) })"
        }
        else {
            $broken++
            Write-Result Fail "broken reference in $($file.FullName.Substring($root.Length + 1)): $target"
        }
    }
}

if ($broken -eq 0 -and $mdFiles.Count -gt 0) {
    Write-Result Info "scanned $($mdFiles.Count) markdown files"
}

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "5. Golden-case corpus integrity" -ForegroundColor Cyan

$casesRoot = Join-Path $root 'tests/cases'
if (-not (Test-Path $casesRoot)) {
    Write-Result Fail 'missing tests/cases directory'
}
else {
    $caseDirs = Get-ChildItem -Path $casesRoot -Directory -Recurse |
        Where-Object { Test-Path (Join-Path $_.FullName 'transform.xsl') }

    if (-not $caseDirs) {
        Write-Result Fail 'no golden cases found under tests/cases/'
    }

    foreach ($case in $caseDirs) {
        $relative = "tests/cases/$($case.FullName.Substring($casesRoot.Length + 1) -replace '\\','/')"

        if ((Test-Path (Join-Path $case.FullName 'expected.xml')) -or
            (Test-Path (Join-Path $case.FullName 'expected.txt'))) {
            Write-Result Pass "has expected.xml/expected.txt: $relative"
        }
        else {
            Write-Result Fail "missing expected.xml and expected.txt: $relative"
        }

        $metaPath = Join-Path $case.FullName 'meta.json'
        if (-not (Test-Path $metaPath)) {
            Write-Result Fail "missing meta.json: $relative"
        }
        else {
            try {
                $meta = Get-Content -Path $metaPath -Raw | ConvertFrom-Json
                if ($meta.PSObject.Properties['source']) {
                    Write-Result Pass "meta.json parses with source field: $relative"
                }
                else {
                    Write-Result Fail "meta.json lacks 'source' field: $relative"
                }
            }
            catch {
                Write-Result Fail "meta.json does not parse: $relative — $($_.Exception.Message)"
            }
        }
    }

    Write-Result Info "$($caseDirs.Count) golden cases under tests/cases/"
}

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "6. Fytala Docs Kit branding" -ForegroundColor Cyan

# 6a. Kit marker file.
$kitMarker = Join-Path $root '.fytala-docs.json'
if (-not (Test-Path $kitMarker)) {
    Write-Result Fail 'missing .fytala-docs.json (Fytala Docs Kit marker)'
}
else {
    try {
        $kit = Get-Content -Path $kitMarker -Raw | ConvertFrom-Json
        if ($kit.PSObject.Properties['kitVersion'] -and $kit.PSObject.Properties['manifest']) {
            Write-Result Pass ".fytala-docs.json present (kit v$($kit.kitVersion))"
        }
        else {
            Write-Result Fail '.fytala-docs.json lacks kitVersion/manifest fields'
        }
    }
    catch {
        Write-Result Fail ".fytala-docs.json does not parse: $($_.Exception.Message)"
    }
}

# 6b. Kit asset integrity — every manifest file present with a matching SHA-256.
$manifestPath = Join-Path $root 'docs-kit/manifest.json'
if (Test-Path $manifestPath) {
    try {
        $manifest = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
        foreach ($entry in $manifest.files) {
            $dest = Join-Path $root $entry.destination
            if (-not (Test-Path $dest)) {
                Write-Result Fail "kit asset missing: $($entry.destination)"
                continue
            }
            $hash = (Get-FileHash -Path $dest -Algorithm SHA256).Hash.ToLower()
            if ($hash -eq $entry.sha256) {
                Write-Result Pass "kit asset integrity: $($entry.destination)"
            }
            else {
                Write-Result Fail "kit asset SHA-256 mismatch: $($entry.destination) — resync from the Prime docs-kit"
            }
        }
    }
    catch {
        Write-Result Fail "docs-kit/manifest.json does not parse: $($_.Exception.Message)"
    }
}
else {
    Write-Result Fail 'missing docs-kit/manifest.json'
}

# 6c. Branded banner on canonical documents; (c) Fytala footer on repo-owned ones.
# Kit-managed files (hash-pinned in docs-kit/manifest.json, e.g. the style guide)
# are exempt from the footer requirement.
$brandedDocs = @(
    @{ Path = 'README.md';                         Logo = 'assets/logos/fytala-logo-color-dark.svg';    Name = 'Bosak.Exslt';                    KitManaged = $false },
    @{ Path = 'ROADMAP.md';                        Logo = 'assets/logos/fytala-logo-color-dark.svg';    Name = 'Bosak.Exslt Roadmap';            KitManaged = $false },
    @{ Path = 'docs/ARCHITECTURE.md';              Logo = '../assets/logos/fytala-logo-color-dark.svg'; Name = 'Bosak.Exslt Architecture';       KitManaged = $false },
    @{ Path = 'docs/COMPATIBILITY.md';             Logo = '../assets/logos/fytala-logo-color-dark.svg'; Name = 'EXSLT Compatibility Matrix';     KitManaged = $false },
    @{ Path = 'docs/FEATURE_REQUESTS.md';          Logo = '../assets/logos/fytala-logo-color-dark.svg'; Name = 'Bosak.Exslt Feature Requests';   KitManaged = $false },
    @{ Path = 'docs/DOCUMENTATION_STYLE_GUIDE.md'; Logo = '../assets/logos/fytala-logo-color-dark.svg'; Name = 'Fytala Documentation Style Guide'; KitManaged = $true }
)

foreach ($doc in $brandedDocs) {
    $path = Join-Path $root $doc.Path
    if (-not (Test-Path $path)) {
        Write-Result Fail "missing branded document: $($doc.Path)"
        continue
    }
    $text = Get-Content -Path $path -Raw
    $bannerOk = $text -match [regex]::Escape($doc.Logo) -and $text -match 'alt="Fytala [^"]+"'
    if ($bannerOk) {
        Write-Result Pass "branded banner with meaningful alt text: $($doc.Path)"
    }
    else {
        Write-Result Fail "branded banner missing or lacking Fytala alt text: $($doc.Path)"
    }
    if ($doc.KitManaged) { continue }
    if ($text -match '© Fytala') {
        Write-Result Pass "(c) Fytala footer: $($doc.Path)"
    }
    else {
        Write-Result Fail "(c) Fytala footer missing: $($doc.Path)"
    }
}

# 6d. About FYTALA statement in the README.
$readmePath = Join-Path $root 'README.md'
if (Test-Path $readmePath) {
    $readme = Get-Content -Path $readmePath -Raw
    if ($readme -match '## About FYTALA' -and $readme -match 'Feeling Young, Thriving, Active, Learning Always') {
        Write-Result Pass 'About FYTALA statement in README.md'
    }
    else {
        Write-Result Fail 'About FYTALA statement missing or altered in README.md'
    }
}

# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "Summary" -ForegroundColor Cyan
Write-Host "  Passed:  $pass"
Write-Host "  Failed:  $fail"
Write-Host "  Warnings: $warn"

if ($Strict -and $warn -gt 0) {
    Write-Host ""
    Write-Host "STRICT MODE: warnings treated as failures." -ForegroundColor Red
    exit 1
}

if ($fail -gt 0) {
    Write-Host ""
    Write-Host "CHECKS FAILED" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "ALL CHECKS PASSED" -ForegroundColor Green
exit 0
