# 修复并部署脚本（需要管理员权限）

Write-Host "停止IIS..." -ForegroundColor Yellow
Stop-Service W3SVC -Force

Start-Sleep -Seconds 2

Write-Host "清理旧文件..." -ForegroundColor Yellow
Remove-Item "C:\inetpub\wwwroot\*" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "复制新文件..." -ForegroundColor Yellow
Copy-Item -Path ".\dist\*" -Destination "C:\inetpub\wwwroot\" -Recurse -Force

Write-Host "启动IIS..." -ForegroundColor Yellow
Start-Service W3SVC

Write-Host "✓ 部署完成！" -ForegroundColor Green
Write-Host ""
Write-Host "访问: http://localhost" -ForegroundColor Cyan

Start-Sleep -Seconds 2
Start-Process "http://localhost"
