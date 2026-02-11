# GitHub仓库配置助手脚本

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  GitHub Actions 部署配置助手" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. 获取GitHub信息
Write-Host "步骤 1/4: 配置GitHub仓库" -ForegroundColor Yellow
Write-Host ""
$githubUsername = Read-Host "请输入你的GitHub用户名"
$repoName = Read-Host "请输入仓库名称 (默认: iis-login-app)"
if ([string]::IsNullOrWhiteSpace($repoName)) {
    $repoName = "iis-login-app"
}

$repoUrl = "https://github.com/$githubUsername/$repoName.git"

Write-Host ""
Write-Host "仓库URL: $repoUrl" -ForegroundColor Green
Write-Host ""

# 2. 提示创建GitHub仓库
Write-Host "步骤 2/4: 创建GitHub仓库" -ForegroundColor Yellow
Write-Host ""
Write-Host "请按以下步骤操作：" -ForegroundColor Cyan
Write-Host "1. 访问: https://github.com/new" -ForegroundColor White
Write-Host "2. Repository name: $repoName" -ForegroundColor White
Write-Host "3. 选择 Private 或 Public" -ForegroundColor White
Write-Host "4. 不要勾选 'Add a README file'" -ForegroundColor White
Write-Host "5. 点击 'Create repository'" -ForegroundColor White
Write-Host ""
$created = Read-Host "已创建仓库？(y/n)"

if ($created -ne "y") {
    Write-Host "请先创建GitHub仓库，然后重新运行此脚本" -ForegroundColor Red
    exit
}

# 3. 关联并推送
Write-Host ""
Write-Host "步骤 3/4: 推送代码到GitHub" -ForegroundColor Yellow
Write-Host ""

try {
    git remote add origin $repoUrl
    git branch -M main
    git push -u origin main
    Write-Host "✓ 代码已推送到GitHub" -ForegroundColor Green
} catch {
    Write-Host "推送失败，可能已经关联过远程仓库" -ForegroundColor Yellow
    Write-Host "尝试直接推送..." -ForegroundColor Yellow
    git push -u origin main
}

# 4. 配置Secrets提示
Write-Host ""
Write-Host "步骤 4/4: 配置GitHub Secrets" -ForegroundColor Yellow
Write-Host ""
Write-Host "请访问: https://github.com/$githubUsername/$repoName/settings/secrets/actions" -ForegroundColor Cyan
Write-Host ""
Write-Host "添加以下4个Secrets：" -ForegroundColor White
Write-Host ""

Write-Host "Secret 1:" -ForegroundColor Yellow
Write-Host "  Name:  IIS_SITE_NAME" -ForegroundColor White
Write-Host "  Value: Default Web Site" -ForegroundColor Gray
Write-Host ""

Write-Host "Secret 2:" -ForegroundColor Yellow
Write-Host "  Name:  IIS_SITE_PATH" -ForegroundColor White
Write-Host "  Value: C:\inetpub\wwwroot" -ForegroundColor Gray
Write-Host ""

Write-Host "Secret 3:" -ForegroundColor Yellow
Write-Host "  Name:  BACKUP_PATH" -ForegroundColor White
Write-Host "  Value: C:\IISBackups" -ForegroundColor Gray
Write-Host ""

Write-Host "Secret 4:" -ForegroundColor Yellow
Write-Host "  Name:  HEALTH_CHECK_URL" -ForegroundColor White
Write-Host "  Value: http://localhost" -ForegroundColor Gray
Write-Host ""

# 5. Self-hosted Runner提示
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "下一步：在IIS服务器上安装Runner" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "访问: https://github.com/$githubUsername/$repoName/settings/actions/runners/new" -ForegroundColor White
Write-Host ""
Write-Host "或者使用自动化脚本（在IIS服务器上运行）：" -ForegroundColor Yellow
Write-Host ""
Write-Host ".\scripts\install-runner.ps1 ``" -ForegroundColor White
Write-Host "    -GitHubToken `"ghp_your_token`" ``" -ForegroundColor White
Write-Host "    -RepoUrl `"$repoUrl`" ``" -ForegroundColor White
Write-Host "    -RunnerName `"IIS-Server-01`"" -ForegroundColor White
Write-Host ""

Write-Host "========================================" -ForegroundColor Green
Write-Host "  配置完成！" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "详细步骤请查看: DEPLOY-STEPS.md" -ForegroundColor Cyan
