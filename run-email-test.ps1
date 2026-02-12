# 运行邮件发送测试脚本
# 用途：手动触发邮件发送测试

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Quant.Infra.Net 邮件发送测试" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$testProject = "Quant.Infra.Net\Quant.Infra.Net.Tests\Quant.Infra.Net.Tests.csproj"
$testFilter = "FullyQualifiedName=Quant.Infra.Net.Tests.EmailIntegrationTests.MVP_SendCommercial"

Write-Host "测试项目: $testProject" -ForegroundColor Yellow
Write-Host "测试方法: MVP_SendCommercial" -ForegroundColor Yellow
Write-Host ""

Write-Host "开始运行测试..." -ForegroundColor Green
Write-Host ""

try {
    dotnet test $testProject --filter $testFilter --logger "console;verbosity=normal"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "  ✓ 测试成功！邮件已发送" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "收件人:" -ForegroundColor Cyan
        Write-Host "  - yuanyuancomecome@outlook.com" -ForegroundColor White
        Write-Host "  - rong.fan1031@gmail.com" -ForegroundColor White
        Write-Host ""
    } else {
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Red
        Write-Host "  ✗ 测试失败" -ForegroundColor Red
        Write-Host "========================================" -ForegroundColor Red
        Write-Host ""
    }
} catch {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  ✗ 发生错误: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
}

Write-Host "按任意键退出..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
