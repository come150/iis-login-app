# 简化版Runner安装脚本
# 在IIS服务器上以管理员身份运行

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GitHub Self-hosted Runner 安装" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "错误：需要管理员权限！" -ForegroundColor Red
    Write-Host "请以管理员身份运行PowerShell" -ForegroundColor Yellow
    exit 1
}

# 创建目录
$runnerDir = "C:\actions-runner"
Write-Host "创建目录: $runnerDir" -ForegroundColor Yellow
if (-not (Test-Path $runnerDir)) {
    New-Item -ItemType Directory -Path $runnerDir -Force | Out-Null
}
Set-Location $runnerDir

# 下载最新版本
Write-Host "下载GitHub Actions Runner..." -ForegroundColor Yellow
$latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/actions/runner/releases/latest"
$asset = $latestRelease.assets | Where-Object { $_.name -like "*win-x64*.zip" } | Select-Object -First 1

if (-not $asset) {
    Write-Host "错误：无法找到Windows x64版本" -ForegroundColor Red
    exit 1
}

$downloadUrl = $asset.browser_download_url
$zipFile = "actions-runner.zip"

Write-Host "下载地址: $downloadUrl" -ForegroundColor Gray
Invoke-WebRequest -Uri $downloadUrl -OutFile $zipFile

# 解压
Write-Host "解压文件..." -ForegroundColor Yellow
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD\$zipFile", "$PWD")
Remove-Item $zipFile -Force

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  下载完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# 获取注册token的说明
Write-Host "接下来需要配置Runner：" -ForegroundColor Cyan
Write-Host ""
Write-Host "步骤1：获取注册Token" -ForegroundColor Yellow
Write-Host "访问: https://github.com/come150/iis-login-app/settings/actions/runners/new" -ForegroundColor White
Write-Host "或者在仓库页面：Settings > Actions > Runners > New self-hosted runner" -ForegroundColor White
Write-Host ""
Write-Host "步骤2：复制页面上的配置命令中的Token" -ForegroundColor Yellow
Write-Host "类似: .\config.cmd --url https://github.com/come150/iis-login-app --token XXXXX" -ForegroundColor White
Write-Host ""

$token = Read-Host "请输入Token（从GitHub页面复制）"

if ([string]::IsNullOrWhiteSpace($token)) {
    Write-Host ""
    Write-Host "未输入Token，请手动运行以下命令：" -ForegroundColor Yellow
    Write-Host ""
    Write-Host ".\config.cmd --url https://github.com/come150/iis-login-app --token YOUR_TOKEN" -ForegroundColor White
    Write-Host ""
    exit 0
}

# 配置Runner
Write-Host ""
Write-Host "配置Runner..." -ForegroundColor Yellow
.\config.cmd --url https://github.com/come150/iis-login-app `
             --token $token `
             --name "IIS-Server-01" `
             --labels "self-hosted,windows,iis" `
             --work "_work" `
             --unattended `
             --replace

if ($LASTEXITCODE -ne 0) {
    Write-Host "配置失败！" -ForegroundColor Red
    exit 1
}

Write-Host "Runner配置成功！" -ForegroundColor Green

# 安装为服务
Write-Host ""
Write-Host "安装为Windows服务..." -ForegroundColor Yellow
.\svc.cmd install

if ($LASTEXITCODE -ne 0) {
    Write-Host "服务安装失败！" -ForegroundColor Red
    exit 1
}

# 启动服务
Write-Host "启动服务..." -ForegroundColor Yellow
.\svc.cmd start

if ($LASTEXITCODE -ne 0) {
    Write-Host "服务启动失败！" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  安装完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Runner名称: IIS-Server-01" -ForegroundColor Cyan
Write-Host "工作目录: $runnerDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "验证状态：" -ForegroundColor Yellow
Write-Host "访问: https://github.com/come150/iis-login-app/settings/actions/runners" -ForegroundColor White
Write-Host "应该看到Runner显示为 Idle（绿色）" -ForegroundColor White
