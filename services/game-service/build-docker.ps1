# ========================================
# Build Script for Game Service Docker Image
# ========================================

param(
    [string]$ImageName = "game-service",
    [string]$Tag = "latest",
    [string]$Region = "ap-southeast-1",
    [string]$AccountId = "",
    [switch]$Push
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Building Game Service Docker Image" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Build Docker image
Write-Host "Building Docker image..." -ForegroundColor Green
docker build -t "${ImageName}:${Tag}" .

if ($LASTEXITCODE -ne 0) {
    Write-Host "Docker build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "Docker image built successfully: ${ImageName}:${Tag}" -ForegroundColor Green

# If Push flag is set, push to ECR
if ($Push) {
    if ([string]::IsNullOrEmpty($AccountId)) {
        Write-Host "Error: AccountId is required for pushing to ECR" -ForegroundColor Red
        Write-Host "Usage: .\build-docker.ps1 -Push -AccountId YOUR_ACCOUNT_ID" -ForegroundColor Yellow
        exit 1
    }

    $ecrRepo = "${AccountId}.dkr.ecr.${Region}.amazonaws.com/${ImageName}"
    
    Write-Host "Logging into ECR..." -ForegroundColor Green
    aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin "${AccountId}.dkr.ecr.${Region}.amazonaws.com"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ECR login failed!" -ForegroundColor Red
        exit 1
    }

    Write-Host "Tagging image for ECR..." -ForegroundColor Green
    docker tag "${ImageName}:${Tag}" "${ecrRepo}:${Tag}"
    
    Write-Host "Pushing to ECR..." -ForegroundColor Green
    docker push "${ecrRepo}:${Tag}"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "========================================" -ForegroundColor Cyan
        Write-Host "Image pushed successfully!" -ForegroundColor Green
        Write-Host "ECR Image: ${ecrRepo}:${Tag}" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Cyan
    } else {
        Write-Host "Push to ECR failed!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Build complete!" -ForegroundColor Green
    Write-Host "To push to ECR, run:" -ForegroundColor Yellow
    Write-Host ".\build-docker.ps1 -Push -AccountId YOUR_ACCOUNT_ID" -ForegroundColor Yellow
    Write-Host "========================================" -ForegroundColor Cyan
}
