# ========================================
# Build Script for Text Service Lambda
# ========================================

param(
    [string]$BuildDir = "..\..\build\text-service-lambda",
    [string]$OutputZip = "..\..\build\text-service-lambda.zip"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building Text Service for AWS Lambda" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Clean previous build
if (Test-Path $BuildDir) {
    Write-Host "Cleaning previous build..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $BuildDir
}

# Create build directory
Write-Host "Creating build directory..." -ForegroundColor Green
New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null

# Create virtual environment
Write-Host "Creating virtual environment..." -ForegroundColor Green
python -m venv venv-build

# Activate virtual environment and install dependencies
Write-Host "Installing dependencies..." -ForegroundColor Green
& ".\venv-build\Scripts\Activate.ps1"
pip install --upgrade pip
pip install -r requirements.txt
pip install mangum  # Lambda adapter for FastAPI
pip install boto3   # AWS SDK for DynamoDB and Bedrock

# Copy installed packages (excluding unnecessary files)
Write-Host "Copying Python packages..." -ForegroundColor Green
$sitePackages = ".\venv-build\Lib\site-packages"
Get-ChildItem -Path $sitePackages | Where-Object { 
    $_.Name -notlike "*.dist-info" -and 
    $_.Name -notlike "__pycache__" -and
    $_.Name -notlike "pip*" -and
    $_.Name -notlike "setuptools*" -and
    $_.Name -notlike "wheel*"
} | ForEach-Object {
    Copy-Item -Recurse -Path $_.FullName -Destination $BuildDir
}

# Copy application code
Write-Host "Copying application code..." -ForegroundColor Green
Copy-Item "main.py" -Destination "$BuildDir\main.py"
Copy-Item "lambda_handler.py" -Destination "$BuildDir\lambda_handler.py"

if (Test-Path "controllers") {
    Copy-Item -Recurse -Path "controllers" -Destination "$BuildDir\controllers"
}

if (Test-Path "models") {
    Copy-Item -Recurse -Path "models" -Destination "$BuildDir\models"
}

Write-Host "Lambda handler ready" -ForegroundColor Green

# Remove unnecessary files to reduce package size
Write-Host "Removing unnecessary files..." -ForegroundColor Green
$cleanupPatterns = @(
    "*.pyc",
    "*.pyo",
    "*__pycache__*",
    "*.dist-info",
    "*.egg-info",
    "tests",
    "test",
    "*.md",
    "*.txt",
    "*.rst"
)

foreach ($pattern in $cleanupPatterns) {
    Get-ChildItem -Path $BuildDir -Recurse -Filter $pattern -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

# Deactivate virtual environment
deactivate

# Remove virtual environment
Write-Host "Cleaning up virtual environment..." -ForegroundColor Yellow
Remove-Item -Recurse -Force "venv-build"

# Create ZIP file
Write-Host "Creating ZIP file..." -ForegroundColor Green
if (Test-Path $OutputZip) {
    Remove-Item -Force $OutputZip
}

# Ensure parent directory exists
$outputDir = Split-Path -Parent $OutputZip
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
}

Compress-Archive -Path "$BuildDir\*" -DestinationPath $OutputZip -Force

# Get file size
$fileSize = (Get-Item $OutputZip).Length / 1MB
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Build Complete!" -ForegroundColor Green
Write-Host "Output: $OutputZip" -ForegroundColor Green
Write-Host "Size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
