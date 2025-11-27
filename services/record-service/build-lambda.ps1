# ========================================
# Build Script for Record Service Lambda
# ========================================

param(
    [string]$BuildDir = "..\..\build\record-service-lambda",
    [string]$OutputZip = "..\..\build\record-service-lambda.zip"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building Record Service for AWS Lambda" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Clean previous build
if (Test-Path $BuildDir) {
    Write-Host "Cleaning previous build..." -ForegroundColor Yellow
    Remove-Item -Recurse -Force $BuildDir
}

# Create build directory
Write-Host "Creating build directory..." -ForegroundColor Green
New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null

# Build TypeScript first (with dev dependencies)
Write-Host "Building TypeScript..." -ForegroundColor Green
npm run build

# Install production dependencies only
Write-Host "Installing production dependencies..." -ForegroundColor Green
npm ci --omit=dev

# Generate Prisma Client
Write-Host "Generating Prisma Client..." -ForegroundColor Green
npx prisma generate

# Copy built files
Write-Host "Copying built files..." -ForegroundColor Green
Copy-Item -Recurse -Path "dist" -Destination "$BuildDir\dist"
Copy-Item -Recurse -Path "node_modules" -Destination "$BuildDir\node_modules"
Copy-Item "package.json" -Destination "$BuildDir\package.json"
Copy-Item "package-lock.json" -Destination "$BuildDir\package-lock.json" -ErrorAction SilentlyContinue

# Copy Prisma files
if (Test-Path "prisma") {
    Write-Host "Copying Prisma schema..." -ForegroundColor Green
    New-Item -ItemType Directory -Path "$BuildDir\prisma" -Force | Out-Null
    Copy-Item "prisma\schema.prisma" -Destination "$BuildDir\prisma\schema.prisma"
}

# Lambda handler is now built from TypeScript (src/lambda.ts -> dist/lambda.js)
Write-Host "Lambda handler compiled from TypeScript" -ForegroundColor Green

# Remove development files
Write-Host "Removing unnecessary files..." -ForegroundColor Green
if (Test-Path "$BuildDir\node_modules\.cache") {
    Remove-Item -Recurse -Force "$BuildDir\node_modules\.cache" -ErrorAction SilentlyContinue
}

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

# Reinstall dev dependencies
Write-Host "Reinstalling all dependencies..." -ForegroundColor Yellow
npm install
