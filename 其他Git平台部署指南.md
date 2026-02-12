# 其他Git平台自动化部署IIS指南

适用于GitLab、Gitea、Gogs、Azure DevOps等Git平台

## 方案对比

| Git平台 | CI/CD工具 | Runner类型 | 配置文件 |
|---------|-----------|-----------|----------|
| GitHub | GitHub Actions | Self-hosted Runner | `.github/workflows/*.yml` |
| GitLab | GitLab CI/CD | GitLab Runner | `.gitlab-ci.yml` |
| Gitea | Gitea Actions | Act Runner | `.gitea/workflows/*.yml` |
| Azure DevOps | Azure Pipelines | Self-hosted Agent | `azure-pipelines.yml` |
| 其他 | Jenkins/自定义 | Jenkins Agent | `Jenkinsfile` |

---

## 方案一：GitLab CI/CD

### 1. 安装GitLab Runner

在IIS服务器上以管理员身份运行：

```powershell
# 下载GitLab Runner
Invoke-WebRequest -Uri "https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-windows-amd64.exe" -OutFile "C:\GitLab-Runner\gitlab-runner.exe"

# 注册Runner
cd C:\GitLab-Runner
.\gitlab-runner.exe register

# 按提示输入：
# GitLab URL: https://gitlab.com/ (或你的私有GitLab地址)
# Token: 从GitLab项目获取
# Description: IIS-Deploy-Runner
# Tags: iis,windows,deploy
# Executor: shell

# 安装为服务
.\gitlab-runner.exe install
.\gitlab-runner.exe start
```

### 2. 创建 `.gitlab-ci.yml`

在项目根目录创建：

```yaml
stages:
  - deploy

deploy-to-iis:
  stage: deploy
  tags:
    - iis
    - windows
  only:
    - main
  script:
    - echo "开始部署到IIS..."
    - |
      $sourcePath = "$CI_PROJECT_DIR\src"
      $targetPath = "C:\inetpub\wwwroot\你的项目"
      
      Write-Host "复制文件..."
      Copy-Item -Path "$sourcePath\*" -Destination $targetPath -Recurse -Force
      
      Write-Host "部署完成！"
  when: manual
```

### 3. 获取Runner Token

1. 访问GitLab项目
2. Settings > CI/CD > Runners
3. 展开 "Specific runners"
4. 复制 Registration token

---

## 方案二：Gitea Actions

Gitea 1.19+支持类似GitHub Actions的功能。

### 1. 安装Act Runner

```powershell
# 下载Act Runner
Invoke-WebRequest -Uri "https://dl.gitea.com/act_runner/latest/act_runner-latest-windows-amd64.exe" -OutFile "C:\act-runner\act-runner.exe"

cd C:\act-runner

# 注册Runner
.\act-runner.exe register --instance https://你的gitea地址 --token YOUR_TOKEN --name "IIS-Runner" --labels "windows,iis"

# 安装为服务
.\act-runner.exe install
.\act-runner.exe start
```

### 2. 创建 `.gitea/workflows/deploy.yml`

```yaml
name: Deploy to IIS

on:
  workflow_dispatch:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: windows
    
    steps:
      - name: 部署到IIS
        run: |
          $sourcePath = "${{ github.workspace }}\src"
          $targetPath = "C:\inetpub\wwwroot\你的项目"
          
          Write-Host "开始部署..."
          Copy-Item -Path "$sourcePath\*" -Destination $targetPath -Recurse -Force
          Write-Host "部署完成！"
        shell: powershell
```

---

## 方案三：Azure DevOps

### 1. 安装Self-hosted Agent

```powershell
# 下载Agent
mkdir C:\azagent
cd C:\azagent

# 从Azure DevOps下载agent包
# 访问: https://dev.azure.com/你的组织/_settings/agentpools
# 下载Windows x64 agent

# 解压并配置
.\config.cmd

# 安装为服务
.\config.cmd --runAsService
```

### 2. 创建 `azure-pipelines.yml`

```yaml
trigger:
  - main

pool:
  name: Default
  demands:
    - agent.name -equals IIS-Agent

steps:
  - task: PowerShell@2
    displayName: '部署到IIS'
    inputs:
      targetType: 'inline'
      script: |
        $sourcePath = "$(Build.SourcesDirectory)\src"
        $targetPath = "C:\inetpub\wwwroot\你的项目"
        
        Write-Host "开始部署..."
        Copy-Item -Path "$sourcePath\*" -Destination $targetPath -Recurse -Force
        Write-Host "部署完成！"
```

---

## 方案四：Jenkins（最通用）

适用于任何Git平台。

### 1. 安装Jenkins

```powershell
# 下载Jenkins
Invoke-WebRequest -Uri "https://get.jenkins.io/windows-stable/latest" -OutFile "jenkins.msi"

# 安装Jenkins
msiexec /i jenkins.msi

# 访问 http://localhost:8080 完成初始化
```

### 2. 配置Jenkins Job

1. 新建任务 > 自由风格项目
2. 源码管理 > Git
   - Repository URL: 你的Git仓库地址
   - Credentials: 添加Git凭据
3. 构建触发器 > 勾选 "GitHub hook trigger" 或 "Poll SCM"
4. 构建 > 增加构建步骤 > Execute Windows batch command

```batch
@echo off
echo 开始部署...

set SOURCE=%WORKSPACE%\src
set TARGET=C:\inetpub\wwwroot\你的项目

xcopy /E /Y /I "%SOURCE%\*" "%TARGET%\"

echo 部署完成！
```

### 3. 配置Webhook

在Git平台配置Webhook：
- URL: `http://你的Jenkins地址/git/notifyCommit?url=你的仓库地址`
- 触发事件: Push events

---

## 方案五：简单脚本方案（无CI/CD平台）

如果不想安装CI/CD工具，可以使用简单的PowerShell脚本+计划任务。

### 1. 创建部署脚本 `auto-deploy.ps1`

```powershell
# 自动部署脚本
$repoPath = "E:\repos\你的项目"
$targetPath = "C:\inetpub\wwwroot\你的项目"

Write-Host "检查更新..." -ForegroundColor Yellow

# 切换到仓库目录
cd $repoPath

# 拉取最新代码
git pull origin main

# 检查是否有更新
$gitStatus = git status --porcelain
if ($LASTEXITCODE -eq 0) {
    Write-Host "发现更新，开始部署..." -ForegroundColor Green
    
    # 复制文件
    Copy-Item -Path "$repoPath\src\*" -Destination $targetPath -Recurse -Force
    
    Write-Host "部署完成！" -ForegroundColor Green
    
    # 记录日志
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path "$repoPath\deploy.log" -Value "[$timestamp] 部署成功"
} else {
    Write-Host "没有更新" -ForegroundColor Gray
}
```

### 2. 创建计划任务

```powershell
# 创建每5分钟检查一次的计划任务
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File E:\repos\你的项目\auto-deploy.ps1"
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName "Auto-Deploy-IIS" -Action $action -Trigger $trigger -Principal $principal
```

---

## 通用部署脚本模板

无论使用哪个平台，核心部署逻辑都是一样的：

```powershell
# 通用IIS部署脚本
param(
    [string]$SourcePath,
    [string]$TargetPath
)

Write-Host "========== 开始部署 ==========" -ForegroundColor Cyan
Write-Host "源路径: $SourcePath"
Write-Host "目标路径: $TargetPath"

# 1. 备份（可选）
$backupPath = "C:\IISBackups\Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Write-Host "创建备份: $backupPath"
Copy-Item -Path "$TargetPath\*" -Destination $backupPath -Recurse -Force -ErrorAction SilentlyContinue

# 2. 停止IIS（可选）
# Import-Module WebAdministration
# Stop-Website -Name "你的站点"

# 3. 部署文件
Write-Host "部署文件..."
Copy-Item -Path "$SourcePath\*" -Destination $TargetPath -Recurse -Force

# 4. 启动IIS（可选）
# Start-Website -Name "你的站点"

Write-Host "========== 部署完成 ==========" -ForegroundColor Green
```

---

## 选择建议

| 场景 | 推荐方案 |
|------|---------|
| 使用GitLab | GitLab CI/CD |
| 使用Gitea | Gitea Actions |
| 使用Azure DevOps | Azure Pipelines |
| 任何Git平台 | Jenkins |
| 简单项目 | PowerShell脚本 + 计划任务 |
| 已有GitHub经验 | 考虑迁移到GitHub |

---

## 快速对比

### GitLab CI/CD
- ✅ 功能强大
- ✅ 免费版功能完整
- ✅ 私有部署支持好
- ❌ Runner配置稍复杂

### Gitea Actions
- ✅ 轻量级
- ✅ 类似GitHub Actions
- ✅ 易于部署
- ❌ 功能相对简单

### Jenkins
- ✅ 最成熟
- ✅ 插件丰富
- ✅ 支持所有Git平台
- ❌ 配置复杂
- ❌ 资源占用大

### 脚本方案
- ✅ 最简单
- ✅ 无需额外工具
- ✅ 易于理解
- ❌ 功能有限
- ❌ 无Web界面

---

## 需要帮助？

告诉我你使用的是哪个Git平台，我可以提供更详细的配置步骤：
- GitLab
- Gitea
- Gogs
- Azure DevOps
- Bitbucket
- 自建Git服务器
- 其他
