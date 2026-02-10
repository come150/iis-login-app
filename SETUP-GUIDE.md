# GitHub Self-hosted Runner 配置指南

## 第一步：准备IIS服务器

### 1.1 系统要求

- Windows Server 2016或更高版本
- IIS 10.0或更高版本
- PowerShell 5.1或更高版本
- .NET Framework 4.6.2或更高版本

### 1.2 安装必要组件

```powershell
# 以管理员身份运行PowerShell

# 安装IIS（如果未安装）
Install-WindowsFeature -Name Web-Server -IncludeManagementTools

# 安装IIS管理工具
Install-WindowsFeature Web-Mgmt-Tools

# 验证WebAdministration模块
Import-Module WebAdministration
Get-Module WebAdministration
```

## 第二步：创建GitHub Personal Access Token

### 2.1 生成Token

1. 登录GitHub
2. 点击右上角头像 > Settings
3. 左侧菜单选择 Developer settings > Personal access tokens > Tokens (classic)
4. 点击 Generate new token (classic)
5. 设置Token名称：`Self-hosted Runner Token`
6. 选择权限：
   - ✅ `repo` (完整仓库访问权限)
   - ✅ `workflow` (更新GitHub Actions工作流)
   - ✅ `admin:org` (如果是组织仓库)
7. 点击 Generate token
8. **立即复制Token**（只显示一次）

### 2.2 保存Token

```powershell
# 将Token保存到安全位置
$token = "ghp_your_token_here"
$token | Out-File -FilePath "$env:USERPROFILE\.github-token" -Encoding UTF8
```

## 第三步：安装Self-hosted Runner

### 方式1：使用自动化脚本（推荐）

```powershell
# 下载项目
git clone https://github.com/your-org/your-repo.git
cd your-repo

# 运行安装脚本
.\scripts\install-runner.ps1 `
    -GitHubToken "ghp_your_token_here" `
    -RepoUrl "https://github.com/your-org/your-repo" `
    -RunnerName "IIS-Production-01" `
    -RunnerLabels "self-hosted,windows,iis,production"
```

### 方式2：手动安装

#### 3.1 下载Runner

1. 访问GitHub仓库
2. Settings > Actions > Runners
3. 点击 New self-hosted runner
4. 选择 Windows x64
5. 按照页面指引操作：

```powershell
# 创建目录
mkdir C:\actions-runner
cd C:\actions-runner

# 下载Runner（使用页面提供的最新链接）
Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v2.xxx.x/actions-runner-win-x64-2.xxx.x.zip -OutFile actions-runner-win-x64-2.xxx.x.zip

# 解压
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD/actions-runner-win-x64-2.xxx.x.zip", "$PWD")
```

#### 3.2 配置Runner

```powershell
# 使用页面提供的配置命令
.\config.cmd --url https://github.com/your-org/your-repo --token YOUR_REGISTRATION_TOKEN

# 配置选项：
# - Runner名称: IIS-Production-01
# - Runner组: Default
# - 标签: self-hosted,windows,iis,production
# - 工作目录: _work
```

#### 3.3 安装为Windows服务

```powershell
# 安装服务
.\svc.cmd install

# 启动服务
.\svc.cmd start

# 验证服务状态
.\svc.cmd status
```

## 第四步：配置GitHub仓库

### 4.1 设置Secrets

访问：仓库 > Settings > Secrets and variables > Actions > New repository secret

添加以下Secrets：

```
IIS_SITE_NAME = Default Web Site
IIS_SITE_PATH = C:\inetpub\wwwroot
BACKUP_PATH = C:\IISBackups
HEALTH_CHECK_URL = https://your-site.com/health
```

### 4.2 设置Variables（多环境）

访问：仓库 > Settings > Secrets and variables > Actions > Variables

添加以下Variables：

```
# 开发环境
DEV_SITE_NAME = DevWebSite
DEV_SITE_PATH = C:\inetpub\wwwroot\dev
DEV_URL = https://dev.your-site.com

# 预发布环境
STAGING_SITE_NAME = StagingWebSite
STAGING_SITE_PATH = C:\inetpub\wwwroot\staging
STAGING_URL = https://staging.your-site.com

# 生产环境
PROD_SITE_NAME = ProductionWebSite
PROD_SITE_PATH = C:\inetpub\wwwroot\production
PROD_URL = https://your-site.com
```

### 4.3 配置Environments（可选）

访问：仓库 > Settings > Environments

创建环境：
1. **development** - 无需审批
2. **staging** - 可选审批
3. **production** - 必需审批

为production环境设置：
- Required reviewers: 添加审批人
- Wait timer: 0分钟
- Deployment branches: 仅main分支

## 第五步：配置Runner权限

### 5.1 创建专用服务账户（推荐）

```powershell
# 创建本地用户
$password = ConvertTo-SecureString "StrongPassword123!" -AsPlainText -Force
New-LocalUser -Name "GitHubRunner" -Password $password -Description "GitHub Actions Runner Service Account"

# 添加到必要的组
Add-LocalGroupMember -Group "IIS_IUSRS" -Member "GitHubRunner"
Add-LocalGroupMember -Group "Administrators" -Member "GitHubRunner"
```

### 5.2 配置文件系统权限

```powershell
# 授予IIS目录权限
icacls "C:\inetpub\wwwroot" /grant "GitHubRunner:(OI)(CI)F" /T

# 授予备份目录权限
New-Item -ItemType Directory -Path "C:\IISBackups" -Force
icacls "C:\IISBackups" /grant "GitHubRunner:(OI)(CI)F" /T

# 授予Runner工作目录权限
icacls "C:\actions-runner" /grant "GitHubRunner:(OI)(CI)F" /T
```

### 5.3 更改服务账户

```powershell
# 停止服务
.\svc.cmd stop

# 卸载服务
.\svc.cmd uninstall

# 使用新账户重新安装
.\svc.cmd install "GitHubRunner"

# 启动服务
.\svc.cmd start
```

## 第六步：测试部署

### 6.1 手动触发部署

1. 访问GitHub仓库
2. Actions > Manual Deploy
3. 点击 Run workflow
4. 选择环境和参数
5. 点击 Run workflow

### 6.2 验证部署

```powershell
# 检查Runner状态
Get-Service "actions.runner.*"

# 检查IIS站点
Get-Website
Get-WebAppPoolState -Name "YourAppPool"

# 测试网站访问
Invoke-WebRequest -Uri "https://your-site.com" -UseBasicParsing
```

### 6.3 查看日志

```powershell
# Runner日志
Get-Content "C:\actions-runner\_diag\Runner_*.log" -Tail 50

# Worker日志
Get-Content "C:\actions-runner\_diag\Worker_*.log" -Tail 50
```

## 第七步：配置防火墙和网络

### 7.1 允许出站连接

Runner需要访问以下域名：

```
github.com (443)
api.github.com (443)
*.actions.githubusercontent.com (443)
```

### 7.2 配置代理（如需要）

```powershell
# 编辑 .env 文件
cd C:\actions-runner
Add-Content -Path ".env" -Value "HTTPS_PROXY=http://proxy.company.com:8080"
Add-Content -Path ".env" -Value "HTTP_PROXY=http://proxy.company.com:8080"

# 重启服务
.\svc.cmd stop
.\svc.cmd start
```

## 常见问题

### Q1: Runner无法连接到GitHub

**解决方案：**
```powershell
# 测试网络连接
Test-NetConnection github.com -Port 443
Test-NetConnection api.github.com -Port 443

# 检查代理设置
$env:HTTPS_PROXY
$env:HTTP_PROXY

# 查看Runner日志
Get-Content "C:\actions-runner\_diag\Runner_*.log" -Tail 100
```

### Q2: 部署时权限不足

**解决方案：**
```powershell
# 确认服务账户
Get-Service "actions.runner.*" | Select-Object Name, StartName

# 检查IIS权限
Get-Acl "C:\inetpub\wwwroot" | Format-List

# 手动测试部署脚本
.\scripts\deploy-to-iis.ps1 -SiteName "Test" -SitePath "C:\test" -SourcePath ".\build"
```

### Q3: Runner服务无法启动

**解决方案：**
```powershell
# 查看事件日志
Get-EventLog -LogName Application -Source "actions.runner.*" -Newest 10

# 重新配置Runner
.\config.cmd remove --token YOUR_TOKEN
.\config.cmd --url https://github.com/your-org/your-repo --token YOUR_NEW_TOKEN

# 重新安装服务
.\svc.cmd install
.\svc.cmd start
```

### Q4: 部署后网站无法访问

**解决方案：**
```powershell
# 检查IIS状态
Get-Website | Where-Object { $_.Name -eq "YourSite" }
Get-WebAppPoolState -Name "YourAppPool"

# 检查应用程序池
Start-WebAppPool -Name "YourAppPool"
Start-Website -Name "YourSite"

# 查看IIS日志
Get-Content "C:\inetpub\logs\LogFiles\W3SVC1\*.log" -Tail 50
```

## 维护和监控

### 定期任务

```powershell
# 每周清理旧的工作目录
$cleanupScript = @"
Get-ChildItem "C:\actions-runner\_work" -Directory | 
    Where-Object { `$_.CreationTime -lt (Get-Date).AddDays(-7) } | 
    Remove-Item -Recurse -Force
"@

$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-Command `"$cleanupScript`""
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2am
Register-ScheduledTask -TaskName "Cleanup Runner Work" -Action $action -Trigger $trigger
```

### 更新Runner

```powershell
# 停止服务
cd C:\actions-runner
.\svc.cmd stop

# 下载最新版本
# 访问 https://github.com/actions/runner/releases

# 解压并覆盖文件
# ...

# 启动服务
.\svc.cmd start
```

## 下一步

- 配置多个Runner实现负载均衡
- 集成Slack/Teams通知
- 添加自动化测试
- 配置蓝绿部署
- 实现金丝雀发布