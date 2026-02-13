# 邮件发送控制台应用

## 问题背景

在使用 GitHub Actions 运行 `dotnet test` 时，测试代码中的 `Console.WriteLine` 输出被测试框架抑制，导致无法看到邮件发送的详细日志（如 `[Brevo]` 开头的日志）。虽然测试通过，但无法确认邮件是否真实发送。

## 解决方案

创建了一个独立的控制台应用 `Quant.Infra.Net.EmailSender`，直接调用邮件服务发送邮件，而不是通过测试框架。这样所有的 `Console.WriteLine` 输出都会正常显示在 GitHub Actions 日志中。

## 项目结构

```
Quant.Infra.Net/
├── Quant.Infra.Net/                    # 核心类库
├── Quant.Infra.Net.Tests/              # 测试项目（原有）
└── Quant.Infra.Net.EmailSender/        # 新增：邮件发送控制台应用
    ├── Program.cs                       # 主程序
    └── Quant.Infra.Net.EmailSender.csproj
```

## 使用方法

### 1. 本地运行

```powershell
# 配置 User Secrets（首次运行）
dotnet user-secrets set "Email:Commercial:Username" "你的SMTP用户名" --project Quant.Infra.Net\Quant.Infra.Net.EmailSender\Quant.Infra.Net.EmailSender.csproj
dotnet user-secrets set "Email:Commercial:Password" "你的SMTP密钥" --project Quant.Infra.Net\Quant.Infra.Net.EmailSender\Quant.Infra.Net.EmailSender.csproj

# 运行邮件发送程序
dotnet run --project Quant.Infra.Net\Quant.Infra.Net.EmailSender\Quant.Infra.Net.EmailSender.csproj
```

### 2. GitHub Actions 运行

GitHub Actions 工作流已更新为使用控制台应用：

1. 在 GitHub 仓库设置中配置 Secrets：
   - `BREVO_USERNAME`: Brevo SMTP 用户名
   - `BREVO_PASSWORD`: Brevo SMTP 密钥（以 `xsmtpsib-` 开头）

2. 手动触发工作流：
   - 进入 GitHub 仓库的 Actions 页面
   - 选择 "Send Email Test via Quant.Infra.Net" 工作流
   - 点击 "Run workflow"

## 工作流程

1. **配置 Git 代理**：设置代理以访问 GitHub
2. **检出代码**：克隆最新代码
3. **显示项目信息**：列出所有 .csproj 文件
4. **配置 User Secrets**：从 GitHub Secrets 读取凭据并配置到项目
5. **运行邮件发送程序**：执行控制台应用发送邮件
6. **显示结果**：根据退出代码显示成功或失败

## 日志输出

控制台应用会输出详细的日志信息：

```
========================================
  Quant.Infra.Net 邮件发送工具
========================================

配置信息:
  SMTP Server: smtp-relay.brevo.com:587
  Username: a136bf001@smtp-brevo.com
  Password: xsmtpsib-131ed...
  Sender: yuanhw512@gmail.com
  Recipients: yuanyuancomecome@outlook.com, rong.fan1031@gmail.com

✓ 检测到正确的 SMTP 密钥 (xsmtpsib-)

开始发送邮件...

[Brevo] 开始真实邮件发送
[Brevo] 发件人: yuanhw512@gmail.com (Quant Lab System)
[Brevo] 主题: 🎯 量化交易系统邮件测试 - 2026-02-13 15:30:00
[Brevo] 收件人数量: 2
[Brevo] SMTP 服务器: smtp-relay.brevo.com:587
[Brevo] 正在连接到 SMTP 服务器...
[Brevo] ✓ 已连接到 SMTP 服务器
[Brevo] 正在进行身份验证...
[Brevo] ✓ 身份验证成功，用户名: a136bf001@smtp-brevo.com
[Brevo] 正在准备邮件给: yuanyuancomecome@outlook.com
[Brevo] 正在发送邮件至: yuanyuancomecome@outlook.com
[Brevo] ✓ 真实邮件已发送至: yuanyuancomecome@outlook.com
[Brevo] 正在准备邮件给: rong.fan1031@gmail.com
[Brevo] 正在发送邮件至: rong.fan1031@gmail.com
[Brevo] ✓ 真实邮件已发送至: rong.fan1031@gmail.com
[Brevo] 正在断开连接...
[Brevo] 真实邮件发送完成，共发送 2 封邮件

========================================
  ✓ 邮件发送成功！
========================================
```

## 优势

1. **日志可见**：所有 `Console.WriteLine` 输出都会显示在 GitHub Actions 日志中
2. **简单直接**：不依赖测试框架，直接调用邮件服务
3. **易于调试**：可以清楚地看到每一步的执行情况
4. **退出代码**：通过退出代码（0=成功，1=失败）明确表示执行结果

## 与测试项目的对比

| 特性 | 测试项目 (dotnet test) | 控制台应用 (dotnet run) |
|------|----------------------|------------------------|
| Console.WriteLine 输出 | 被抑制 | 正常显示 |
| 日志可见性 | 低 | 高 |
| 调试难度 | 高 | 低 |
| 适用场景 | 单元测试 | 自动化任务 |

## 注意事项

1. **SMTP 密钥格式**：必须使用 SMTP 密钥（`xsmtpsib-` 开头），不能使用 API Key（`xkeysib-` 开头）
2. **User Secrets**：本地开发时需要配置 User Secrets，GitHub Actions 会自动从 Secrets 配置
3. **代理设置**：如果网络需要代理访问 GitHub，确保代理正在运行（127.0.0.1:10809）

## 相关文件

- `Quant.Infra.Net/Quant.Infra.Net.EmailSender/Program.cs` - 主程序
- `.github/workflows/manual-deploy.yml` - GitHub Actions 工作流
- `run-email-test.ps1` - 本地测试脚本（使用测试项目）
