# ========================================
# 本地完整部署脚本
# 需要以管理员身份运行
# ========================================

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  本地IIS + GitHub Runner 完整部署" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 检查管理员权限
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ 错误：需要管理员权限！" -ForegroundColor Red
    Write-Host ""
    Write-Host "请按以下步骤操作：" -ForegroundColor Yellow
    Write-Host "1. 右键点击 PowerShell" -ForegroundColor White
    Write-Host "2. 选择 '以管理员身份运行'" -ForegroundColor White
    Write-Host "3. 重新运行此脚本" -ForegroundColor White
    Write-Host ""
    Read-Host "按回车键退出"
    exit 1
}

Write-Host "✓ 管理员权限检查通过" -ForegroundColor Green
Write-Host ""

# ========================================
# 第一步：安装IIS
# ========================================
Write-Host "第一步：安装IIS" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

$iisInstalled = Get-Service W3SVC -ErrorAction SilentlyContinue
if ($iisInstalled) {
    Write-Host "✓ IIS已安装" -ForegroundColor Green
} else {
    Write-Host "正在安装IIS..." -ForegroundColor Yellow
    
    try {
        Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All -NoRestart | Out-Null
        Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer -All -NoRestart | Out-Null
        Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures -All -NoRestart | Out-Null
        Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementConsole -All -NoRestart | Out-Null
        
        Write-Host "✓ IIS安装完成" -ForegroundColor Green
        Write-Host "⚠ 可能需要重启计算机" -ForegroundColor Yellow
    } catch {
        Write-Host "❌ IIS安装失败: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

Write-Host ""

# ========================================
# 第二步：配置IIS站点
# ========================================
Write-Host "第二步：配置IIS站点" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

# 导入WebAdministration模块
Import-Module WebAdministration -ErrorAction SilentlyContinue

# 设置站点路径
$sitePath = "C:\inetpub\wwwroot"
$siteName = "Default Web Site"

Write-Host "站点名称: $siteName" -ForegroundColor Cyan
Write-Host "站点路径: $sitePath" -ForegroundColor Cyan

# 确保目录存在
if (-not (Test-Path $sitePath)) {
    New-Item -ItemType Directory -Path $sitePath -Force | Out-Null
}

# 部署应用文件
Write-Host "部署应用文件..." -ForegroundColor Yellow
$distPath = Join-Path $PSScriptRoot "dist"

if (Test-Path $distPath) {
    Copy-Item -Path "$distPath\*" -Destination $sitePath -Recurse -Force
    Write-Host "✓ 应用文件已部署" -ForegroundColor Green
} else {
    Write-Host "⚠ dist目录不存在，先运行: npm run build" -ForegroundColor Yellow
}

# 启动IIS
Write-Host "启动IIS服务..." -ForegroundColor Yellow
Start-Service W3SVC -ErrorAction SilentlyContinue
Write-Host "✓ IIS服务已启动" -ForegroundColor Green

Write-Host ""

# ========================================
# 第三步：安装GitHub Runner
# ========================================
Write-Host "第三步：安装GitHub Runner" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Gray

$runnerDir = "C:\actions-runner"

if (Test-Path "$runnerDir\.runner") {
    Write-Host "✓ Runner已安装" -ForegroundColor Green
} else {
    Write-Host "创建Runner目录..." -ForegroundColor Yellow
    if (-not (Test-Path $runnerDir)) {
        New-Item -ItemType Directory -Path $runnerDir -Force | Out-Null
    }
    
    Set-Location $runnerDir
    
    Write-Host "下载GitHub Actions Runner..." -ForegroundColor Yellow
    try {
        $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/actions/runner/releases/latest"
        $asset = $latestRelease.assets | Where-Object { $_.name -like "*win-x64*.zip" } | Select-Object -First 1
        
        if ($asset) {
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile "actions-runner.zip"
            
            Write-Host "解压文件..." -ForegroundColor Yellow
            Expand-Archive -Path "actions-runner.zip" -DestinationPath . -Force
            Remove-Item "actions-runner.zip" -Force
            
            Write-Host "✓ Runner下载完成" -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Runner下载失败: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""

# ========================================
# 第四步：配置说明
# ========================================
Write-Host "========================================" -ForegroundColor Green
Write-Host "  安装完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

Write-Host "接下来的步骤：" -ForegroundColor Cyan
Write-Host ""

Write-Host "1️⃣ 测试IIS网站" -ForegroundColor Yellow
Write-Host "   访问: http://localhost" -ForegroundColor White
Write-Host "   应该能看到登录页面" -ForegroundColor Gray
Write-Host ""

Write-Host "2️⃣ 配置GitHub Runner" -ForegroundColor Yellow
Write-Host "   访问: https://github.com/come150/iis-login-app/settings/actions/runners/new" -ForegroundColor White
Write-Host "   获取Token后运行：" -ForegroundColor Gray
Write-Host ""
Write-Host "   cd C:\actions-runner" -ForegroundColor White
Write-Host "   .\config.cmd --url https://github.com/come150/iis-login-app --token YOUR_TOKEN" -ForegroundColor White
Write-Host "   .\svc.cmd install" -ForegroundColor White
Write-Host "   .\svc.cmd start" -ForegroundColor White
Write-Host ""

Write-Host "3️⃣ 配置GitHub Secrets" -ForegroundColor Yellow
Write-Host "   访问: https://github.com/come150/iis-login-app/settings/secrets/actions" -ForegroundColor White
Write-Host "   添加以下Secrets：" -ForegroundColor Gray
Write-Host "   - IIS_SITE_NAME = Default Web Site" -ForegroundColor White
Write-Host "   - IIS_SITE_PATH = C:\inetpub\wwwroot" -ForegroundColor White
Write-Host "   - BACKUP_PATH = C:\IISBackups" -ForegroundColor White
Write-Host "   - HEALTH_CHECK_URL = http://localhost" -ForegroundColor White
Write-Host ""

Write-Host "4️⃣ 触发部署" -ForegroundColor Yellow
Write-Host "   访问: https://github.com/come150/iis-login-app/actions" -ForegroundColor White
Write-Host "   点击 Manual Deploy > Run workflow" -ForegroundColor Gray
Write-Host ""

Write-Host "详细文档: NEXT-STEPS.md" -ForegroundColor Cyan
Write-Host ""

# 打开浏览器测试
$openBrowser = Read-Host "是否打开浏览器测试IIS？(y/n)"
if ($openBrowser -eq "y") {
    Start-Process "http://localhost"
}
