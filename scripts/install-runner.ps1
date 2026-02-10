# ============================================
# GitHub Self-hosted Runner 安装脚本
# ============================================

param(
    [Parameter(Mandatory=$true)]
    [string]$GitHubToken,
    
    [Parameter(Mandatory=$true)]
    [string]$RepoUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$RunnerName = $env:COMPUTERNAME,
    
    [Parameter(Mandatory=$false)]
    [string]$RunnerLabels = "self-hosted,windows,iis",
    
    [Parameter(Mandatory=$false)]
    [string]$WorkFolder = "C:\actions-runner"
)

Write-Host "========== 安装 GitHub Self-hosted Runner ==========" -ForegroundColor Cyan

# 创建工作目录
if (-not (Test-Path $WorkFolder)) {
    New-Item -ItemType Directory -Path $WorkFolder -Force | Out-Null
    Write-Host "创建工作目录: $WorkFolder" -ForegroundColor Green
}

Set-Location $WorkFolder

# 下载最新版本的 Runner
Write-Host "下载 GitHub Actions Runner..." -ForegroundColor Yellow
$latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/actions/runner/releases/latest"
$asset = $latestRelease.assets | Where-Object { $_.name -like "*win-x64*.zip" } | Select-Object -First 1

if (-not $asset) {
    throw "无法找到 Windows x64 版本的 Runner"
}

$downloadUrl = $asset.browser_download_url
$zipFile = Join-Path $WorkFolder "actions-runner.zip"

Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile
Write-Host "下载完成" -ForegroundColor Green

# 解压
Write-Host "解压文件..." -ForegroundColor Yellow
Expand-Archive -Path $zipFile -DestinationPath $WorkFolder -Force
Remove-Item $zipFile -Force

# 获取注册令牌
Write-Host "获取注册令牌..." -ForegroundColor Yellow
$repoPath = $RepoUrl -replace "https://github.com/", ""
$tokenUrl = "https://api.github.com/repos/$repoPath/actions/runners/registration-token"

$headers = @{
    "Authorization" = "token $GitHubToken"
    "Accept" = "application/vnd.github.v3+json"
}

$tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Headers $headers
$registrationToken = $tokenResponse.token

# 配置 Runner
Write-Host "配置 Runner..." -ForegroundColor Yellow
.\config.cmd --url $RepoUrl `
             --token $registrationToken `
             --name $RunnerName `
             --labels $RunnerLabels `
             --work "_work" `
             --unattended `
             --replace

if ($LASTEXITCODE -ne 0) {
    throw "Runner 配置失败"
}

Write-Host "Runner 配置成功" -ForegroundColor Green

# 安装为 Windows 服务
Write-Host "安装为 Windows 服务..." -ForegroundColor Yellow
.\svc.cmd install

if ($LASTEXITCODE -ne 0) {
    throw "服务安装失败"
}

# 启动服务
Write-Host "启动服务..." -ForegroundColor Yellow
.\svc.cmd start

if ($LASTEXITCODE -ne 0) {
    throw "服务启动失败"
}

Write-Host "========== 安装完成 ==========" -ForegroundColor Green
Write-Host "Runner 名称: $RunnerName" -ForegroundColor Cyan
Write-Host "标签: $RunnerLabels" -ForegroundColor Cyan
Write-Host "工作目录: $WorkFolder" -ForegroundColor Cyan
