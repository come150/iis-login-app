# 安装IIS的脚本（需要管理员权限）
# 以管理员身份运行PowerShell，然后执行此脚本

Write-Host "检查管理员权限..." -ForegroundColor Yellow
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "错误：需要管理员权限！" -ForegroundColor Red
    Write-Host "请以管理员身份运行PowerShell" -ForegroundColor Yellow
    exit 1
}

Write-Host "开始安装IIS..." -ForegroundColor Cyan

# Windows 10/11 使用 Enable-WindowsOptionalFeature
try {
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-HealthAndDiagnostics -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-IIS6ManagementCompatibility -All -NoRestart
    Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementConsole -All -NoRestart
    
    Write-Host "IIS安装完成！" -ForegroundColor Green
    Write-Host "可能需要重启计算机才能生效" -ForegroundColor Yellow
} catch {
    Write-Host "安装失败: $($_.Exception.Message)" -ForegroundColor Red
}
