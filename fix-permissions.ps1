# 修复Runner权限脚本（需要管理员权限）

Write-Host "修复GitHub Runner权限..." -ForegroundColor Yellow

# 授予IIS目录权限
Write-Host "授予IIS目录权限..." -ForegroundColor Cyan
icacls "C:\inetpub\wwwroot" /grant "NT AUTHORITY\NETWORK SERVICE:(OI)(CI)F" /T

# 授予备份目录权限
Write-Host "授予备份目录权限..." -ForegroundColor Cyan
if (-not (Test-Path "C:\IISBackups")) {
    New-Item -ItemType Directory -Path "C:\IISBackups" -Force
}
icacls "C:\IISBackups" /grant "NT AUTHORITY\NETWORK SERVICE:(OI)(CI)F" /T

# 授予IIS配置目录权限
Write-Host "授予IIS配置目录权限..." -ForegroundColor Cyan
icacls "C:\Windows\System32\inetsrv\config" /grant "NT AUTHORITY\NETWORK SERVICE:(OI)(CI)R" /T

# 将Runner服务账户添加到IIS_IUSRS组
Write-Host "添加到IIS_IUSRS组..." -ForegroundColor Cyan
try {
    Add-LocalGroupMember -Group "IIS_IUSRS" -Member "NT AUTHORITY\NETWORK SERVICE" -ErrorAction SilentlyContinue
    Write-Host "✓ 已添加到IIS_IUSRS组" -ForegroundColor Green
} catch {
    Write-Host "账户可能已在组中" -ForegroundColor Gray
}

Write-Host ""
Write-Host "✓ 权限修复完成！" -ForegroundColor Green
Write-Host ""
Write-Host "现在重启Runner服务：" -ForegroundColor Yellow
Write-Host "Restart-Service 'actions.runner.*'" -ForegroundColor White
