# 🎯 接下来的配置步骤

代码已成功推送到GitHub！现在需要完成以下配置：

## 步骤1：配置GitHub Secrets（必需）

### 访问链接：
```
https://github.com/come150/iis-login-app/settings/secrets/actions
```

### 添加4个Secrets：

点击 **"New repository secret"** 按钮，依次添加：

#### Secret 1: IIS_SITE_NAME
- Name: `IIS_SITE_NAME`
- Value: `Default Web Site`
  （如果你的IIS站点名称不同，请修改）

#### Secret 2: IIS_SITE_PATH
- Name: `IIS_SITE_PATH`
- Value: `C:\inetpub\wwwroot`
  （你的IIS站点物理路径）

#### Secret 3: BACKUP_PATH
- Name: `BACKUP_PATH`
- Value: `C:\IISBackups`
  （备份文件存放路径）

#### Secret 4: HEALTH_CHECK_URL
- Name: `HEALTH_CHECK_URL`
- Value: `http://localhost`
  （你的网站访问地址，如果有域名就填域名）

---

## 步骤2：在IIS服务器上安装Self-hosted Runner

### 方式A：使用GitHub网页指引（推荐）

1. 访问：
```
https://github.com/come150/iis-login-app/settings/actions/runners/new
```

2. 选择 **Windows** 和 **x64**

3. 在你的IIS服务器上，以**管理员身份**打开PowerShell

4. 按照页面上的命令依次执行：

```powershell
# 创建目录
mkdir C:\actions-runner
cd C:\actions-runner

# 下载（使用页面提供的最新链接）
Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v2.xxx.x/actions-runner-win-x64-2.xxx.x.zip -OutFile actions-runner.zip

# 解压
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD/actions-runner.zip", "$PWD")

# 配置（使用页面提供的token）
.\config.cmd --url https://github.com/come150/iis-login-app --token YOUR_TOKEN

# 配置选项：
# Runner name: IIS-Server-01
# Runner group: Default
# Labels: self-hosted,windows,iis
# Work folder: _work

# 安装为Windows服务
.\svc.cmd install

# 启动服务
.\svc.cmd start
```

### 方式B：使用自动化脚本

如果你有GitHub Personal Access Token：

```powershell
# 在IIS服务器上下载并运行
cd C:\
git clone https://github.com/come150/iis-login-app.git
cd iis-login-app

.\scripts\install-runner.ps1 `
    -GitHubToken "ghp_your_token_here" `
    -RepoUrl "https://github.com/come150/iis-login-app" `
    -RunnerName "IIS-Server-01"
```

---

## 步骤3：验证配置

### 检查Runner状态

访问：
```
https://github.com/come150/iis-login-app/settings/actions/runners
```

应该看到你的Runner显示为 **Idle**（绿色圆点）

### 检查Secrets

访问：
```
https://github.com/come150/iis-login-app/settings/secrets/actions
```

应该看到4个Secrets已添加

---

## 步骤4：触发第一次部署

### 方式A：手动触发（推荐首次使用）

1. 访问：
```
https://github.com/come150/iis-login-app/actions
```

2. 点击左侧 **"Manual Deploy"**

3. 点击右侧 **"Run workflow"** 按钮

4. 选择参数：
   - Environment: `production`
   - Version: 留空
   - Skip tests: 不勾选

5. 点击绿色的 **"Run workflow"** 确认

6. 等待部署完成（1-3分钟）

### 方式B：推送代码触发

```powershell
# 修改任意文件
echo "# 测试部署" >> README.md

# 提交并推送
git add .
git commit -m "测试自动部署"
git push origin main
```

---

## 步骤5：查看部署结果

### 在GitHub上查看

访问：
```
https://github.com/come150/iis-login-app/actions
```

点击最新的工作流运行，查看详细日志。

### 在IIS服务器上验证

```powershell
# 检查文件是否部署
dir C:\inetpub\wwwroot

# 应该看到：
# - index.html
# - dashboard.html
# - style.css
# - app.js
# - web.config

# 检查IIS站点状态
Import-Module WebAdministration
Get-Website
```

### 访问网站

打开浏览器，访问你的IIS服务器地址，测试登录：
- 用户名: `admin` / 密码: `admin123`
- 用户名: `user` / 密码: `user123`

---

## 🎉 完成检查清单

- [ ] 已推送代码到GitHub
- [ ] 已配置4个GitHub Secrets
- [ ] 已在IIS服务器安装Runner
- [ ] Runner状态显示为Idle
- [ ] 已触发第一次部署
- [ ] 部署工作流成功完成
- [ ] 网站可以正常访问
- [ ] 登录功能正常工作

---

## ❓ 遇到问题？

### Runner无法连接
```powershell
# 检查网络
Test-NetConnection github.com -Port 443

# 查看Runner日志
Get-Content "C:\actions-runner\_diag\Runner_*.log" -Tail 50
```

### 部署失败
```powershell
# 检查IIS
Get-Service W3SVC
Get-Website

# 查看部署日志
# 在GitHub Actions页面查看详细错误信息
```

### 权限问题
```powershell
# 授予Runner权限
icacls "C:\inetpub\wwwroot" /grant "NT AUTHORITY\NETWORK SERVICE:(OI)(CI)F" /T
```

---

## 📚 参考文档

- 详细配置指南: `SETUP-GUIDE.md`
- 完整部署步骤: `DEPLOY-STEPS.md`
- 测试指南: `TEST.md`
- 快速开始: `QUICKSTART.md`
