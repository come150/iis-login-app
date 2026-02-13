# 简单的邮件发送测试
Write-Host "测试邮件发送..." -ForegroundColor Cyan

$testProject = "Quant.Infra.Net\Quant.Infra.Net.Tests\Quant.Infra.Net.Tests.csproj"

# 显示User Secrets
Write-Host "`n当前User Secrets:" -ForegroundColor Yellow
dotnet user-secrets list --project $testProject

# 运行测试
Write-Host "`n运行测试..." -ForegroundColor Yellow
dotnet test $testProject --filter "FullyQualifiedName=Quant.Infra.Net.Tests.EmailIntegrationTests.MVP_SendCommercial" --logger "console;verbosity=detailed" --no-build

Write-Host "`n测试完成，退出码: $LASTEXITCODE" -ForegroundColor $(if ($LASTEXITCODE -eq 0) { "Green" } else { "Red" })
