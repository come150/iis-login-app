# GitHub Actions + Self-hosted Runner 自动化部署IIS

使用GitHub Actions和Self-hosted Runner实现IIS服务器的CI/CD自动化部署。

## 架构说明

```
GitHub Repository
    ↓ (push/PR)
GitHub Actions (构建)
    ↓ (artifact)
Self-hosted Runner (Windows服务器)
    ↓ (部署)
IIS Web Server
```

## 快速开始

### 1. 安装Self-hosted Runner

在IIS服务器上以管理员身份运行：

```powershell
# 方式1：使用安装脚本
.\scripts\install-runner.ps1 `
    -GitHubToken "ghp_your_token_here" `
    -RepoUrl "https://github.com/your-org/your-repo" `
    -RunnerName "IIS-Server-01" `
    -RunnerLabels "self-hosted,windows,iis"

# 方式2：手动安装
# 1. 访问 GitHub仓库 > Settings > Actions > Runners > New self-hosted runner
# 2. 按照页面指引下载并配置Runner
# 3. 安装为Windows服务
```

### 2. 配置GitHub Secrets

在GitHub仓库中设置以下Secrets（Settings > Secrets and variables > Actions）：

**必需的Secrets：**
- `IIS_SITE_NAME`: IIS站点名称（如：Default Web Site）
- `IIS_SITE_PATH`: 站点物理路径（如：C:\inetpub\wwwroot）
- `BACKUP_PATH`: 备份目录路径（如：C:\IISBackups）
- `HEALTH_CHECK_URL`: 健康检查URL（如：https://your-site.com/health）

**可选的Variables（用于多环境）：**
- `DEV_SITE_NAME`, `DEV_SITE_PATH`, `DEV_URL`
- `STAGING_SITE_NAME`, `STAGING_SITE_PATH`, `STAGING_URL`
- `PROD_SITE_NAME`, `PROD_SITE_PATH`, `PROD_URL`

### 3. 部署工作流

提交代码到对应分支即可自动触发部署：

```bash
# 部署到生产环境
git push origin main

# 部署到开发环境
git push origin develop

# 部署到预发布环境
git push origin staging
```

## 工作流说明

### deploy-iis.yml（单环境部署）

适用于简单的单环境部署场景。

**触发条件：**
- 推送到 `main` 或 `production` 分支
- 手动触发（workflow_dispatch）

**流程：**
1. 在Ubuntu Runner上构建项目
2. 上传构建产物
3. 在Self-hosted Runner上部署到IIS
4. 执行健康检查
5. 失败时自动回滚

### deploy-multi-env.yml（多环境部署）

适用于开发、预发布、生产多环境场景。

**触发条件：**
- `develop` 分支 → 开发环境
- `staging` 分支 → 预发布环境
- `main` 分支 → 生产环境

**特性：**
- 环境隔离（使用GitHub Environments）
- 生产环境需要人工审批
- 自动化测试和烟雾测试

## 脚本说明

### scripts/deploy-to-iis.ps1

核心部署脚本，被GitHub Actions调用。

**功能：**
- 停止IIS站点和应用程序池
- 备份当前版本（可选）
- 部署新版本
- 保护web.config配置文件
- 启动服务并验证状态

**使用示例：**
```powershell
.\scripts\deploy-to-iis.ps1 `
    -SiteName "MyWebSite" `
    -SitePath "C:\inetpub\wwwroot\MyApp" `
    -SourcePath ".\build" `
    -EnableBackup
```

### scripts/install-runner.ps1

自动化安装GitHub Self-hosted Runner。

**功能：**
- 下载最新版本的Runner
- 自动注册到GitHub仓库
- 安装为Windows服务
- 配置自动启动

## 配置Runner标签

使用标签来指定部署目标：

```yaml
# 部署到带有特定标签的Runner
runs-on: [self-hosted, windows, iis, production]
```

**推荐标签策略：**
- `self-hosted`: 所有自托管Runner
- `windows`: Windows服务器
- `iis`: IIS服务器
- `dev/staging/production`: 环境标识
- `server-01/server-02`: 服务器标识

## 高级配置

### 多服务器负载均衡部署

```yaml
deploy-cluster:
  runs-on: self-hosted
  strategy:
    matrix:
      server: [server-01, server-02, server-03]
  steps:
    - name: Deploy to ${{ matrix.server }}
      run: |
        .\scripts\deploy-to-iis.ps1 -SiteName "MyApp-${{ matrix.server }}"
```

### 蓝绿部署

```yaml
- name: Deploy to Blue
  run: .\scripts\deploy-to-iis.ps1 -SiteName "MyApp-Blue"

- name: Health Check Blue
  run: Test-WebSite -Url "https://blue.myapp.com"

- name: Switch Traffic to Blue
  run: .\scripts\switch-traffic.ps1 -Target "Blue"
```

### 集成通知

```yaml
- name: 通知部署结果
  if: always()
  uses: 8398a7/action-slack@v3
  with:
    status: ${{ job.status }}
    text: '部署到生产环境: ${{ job.status }}'
    webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

## 前置要求

### IIS服务器要求

1. **Windows Server** 2016或更高版本
2. **IIS** 已安装并配置
3. **PowerShell** 5.1或更高版本
4. **WebAdministration模块** 已安装

```powershell
# 安装IIS管理工具
Install-WindowsFeature Web-Mgmt-Tools
```

### GitHub要求

1. GitHub仓库（公开或私有）
2. 有权限创建Self-hosted Runner的访问令牌
3. 配置好的Secrets和Variables

## 安全最佳实践

1. **使用专用服务账户**运行Runner服务
2. **限制Runner权限**，仅授予必要的IIS管理权限
3. **定期更新Runner**到最新版本
4. **使用GitHub Secrets**存储敏感信息
5. **启用Runner组**进行访问控制
6. **监控Runner日志**，及时发现异常

## 故障排查

### Runner无法连接到GitHub

```powershell
# 检查网络连接
Test-NetConnection github.com -Port 443

# 检查代理设置
$env:HTTPS_PROXY = "http://proxy.company.com:8080"

# 重启Runner服务
Restart-Service "actions.runner.*"
```

### 部署失败

```powershell
# 查看Runner日志
Get-Content "C:\actions-runner\_diag\Runner_*.log" -Tail 50

# 检查IIS状态
Get-Website
Get-WebAppPoolState -Name "YourAppPool"

# 手动测试部署脚本
.\scripts\deploy-to-iis.ps1 -SiteName "Test" -SitePath "C:\test" -SourcePath ".\build"
```

### 权限问题

```powershell
# 确保Runner服务账户有IIS管理权限
Add-LocalGroupMember -Group "IIS_IUSRS" -Member "DOMAIN\RunnerServiceAccount"

# 授予文件系统权限
icacls "C:\inetpub\wwwroot" /grant "DOMAIN\RunnerServiceAccount:(OI)(CI)F"
```

## 监控和维护

### 监控Runner状态

```powershell
# 检查Runner服务
Get-Service "actions.runner.*"

# 查看Runner进程
Get-Process | Where-Object { $_.Name -like "*Runner*" }
```

### 定期维护

```powershell
# 清理旧的工作目录
Remove-Item "C:\actions-runner\_work\*" -Recurse -Force -Older 7days

# 清理旧备份
Get-ChildItem "C:\IISBackups" | 
    Where-Object { $_.CreationTime -lt (Get-Date).AddDays(-30) } | 
    Remove-Item -Recurse -Force
```

## 参考资源

- [GitHub Actions 文档](https://docs.github.com/actions)
- [Self-hosted Runners 指南](https://docs.github.com/actions/hosting-your-own-runners)
- [IIS PowerShell 管理](https://docs.microsoft.com/iis/manage/powershell)
