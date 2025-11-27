# ========================================
# Master Build Script for All Lambda Functions
# ========================================

param(
    [switch]$SkipRecordService,
    [switch]$SkipTextService
)

$ErrorActionPreference = "Stop"
$rootDir = Split-Path $PSScriptRoot -Parent

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building All Lambda Functions" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Ensure build directory exists
$buildDir = Join-Path $rootDir "build"
if (-not (Test-Path $buildDir)) {
    Write-Host "Creating build directory..." -ForegroundColor Green
    New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
}

# Build Record Service
if (-not $SkipRecordService) {
    Write-Host ""
    Write-Host ">>> Building Record Service Lambda..." -ForegroundColor Yellow
    Push-Location (Join-Path $rootDir "services\record-service")
    try {
        & .\build-lambda.ps1
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
            throw "Record Service build failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }
    Write-Host ">>> Record Service build complete!" -ForegroundColor Green
} else {
    Write-Host ">>> Skipping Record Service build" -ForegroundColor Gray
}

# Build Text Service
if (-not $SkipTextService) {
    Write-Host ""
    Write-Host ">>> Building Text Service Lambda..." -ForegroundColor Yellow
    Push-Location (Join-Path $rootDir "services\text-service")
    try {
        & .\build-lambda.ps1
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) {
            throw "Text Service build failed with exit code $LASTEXITCODE"
        }
    }
    finally {
        Pop-Location
    }
    Write-Host ">>> Text Service build complete!" -ForegroundColor Green
} else {
    Write-Host ">>> Skipping Text Service build" -ForegroundColor Gray
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "All Lambda Builds Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Build artifacts location:" -ForegroundColor White
Get-ChildItem -Path $buildDir -Filter "*.zip" | ForEach-Object {
    $size = [math]::Round($_.Length / 1MB, 2)
    Write-Host "  - $($_.Name) ($size MB)" -ForegroundColor Cyan
}
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. cd infras" -ForegroundColor White
Write-Host "  2. terraform init" -ForegroundColor White
Write-Host "  3. terraform plan -var-file=`"dev.auto.tfvars`"" -ForegroundColor White
Write-Host "  4. terraform apply -var-file=`"dev.auto.tfvars`"" -ForegroundColor White
Write-Host ""
