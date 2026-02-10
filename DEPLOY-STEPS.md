# 🚀 GitHub Actions 部署完整步骤

## 第一步：初始化Git仓库

### 1.1 检查Git状态

```powershell
# 检查是否已初始化
git status
```

### 1.2 初始化仓库（如果还没有）

```powershell
# 初始化Git仓库
git init

# 添加所有文件
git add .

# 提交
git commit -m "初始化登录应用项目"
```

### 1.3 创建GitHub仓库

1. 访问 https://github.com/new
2. 填写仓库信息：
   - Repository name: `iis-login-app` (或你喜欢的名字)
   - Description: `GitHub Actions自动部署IIS登录应用`
   - 选择 **Private** 或 **Public**
3. **不要**勾选 "Add a README file"
4. 点击 "Create repository"

### 1.4 关联远程仓库

```powershell
# 添加远程仓库（替换为你的GitHub用户名和仓库名）
git remote add origin https://github.com/YOUR_USERNAME/iis-login-app.git

# 推送代码
git branch -M main
git push -u origin main
```

---

## 第二步：配置GitHub Secrets

### 2.1 访问仓库设置

1. 打开你的GitHub仓库
2. 点击 **Settings** (设置)
3. 左侧菜单选择 **Secrets and variables** > **Actions**
4. 点击 **New repository secret**

### 2.2 添加必需的Secrets

依次添加以下Secrets：

#### Secret 1: IIS_SITE_NAME
- Name: `IIS_SITE_NAME`
- Value: `Default Web Site` (你的IIS站点名称)

#### Secret 2: IIS_SITE_PATH
- Name: `IIS_SITE_PATH`
- Value: `C:\inetpub\wwwroot` (你的IIS站点物理路径)

#### Secret 3: BACKUP_PATH
- Name: `BACKUP_PATH`
- Value: `C:\IISBackups` (备份目录路径)

#### Secret 4: HEALTH_CHECK_URL
- Name: `HEALTH_CHECK_URL`
- Value: `http://localhost` (你的网站URL)

### 2.3 验证Secrets

确保所有4个Secrets都已添加成功。

---

## 第三步：在IIS服务器上安装Self-hosted Runner

### 3.1 准备工作

确保IIS服务器满足：
- ✅ Windows Server 2016+ 或 Windows 10/11
- ✅ 已安装IIS
- ✅ 有管理员权限
- ✅ 可以访问GitHub

### 3.2 获取Runner安装命令

1. 访问你的GitHub仓库
2. 点击 **Settings** > **Actions** > **Runners**
3. 点击 **New self-hosted runner**
4. 选择 **Windows** 和 **x64**
5. 复制页面上的命令

### 3.3 在IIS服务器上执行（方式1：手动）

在IIS服务器上以**管理员身份**打开PowerShell：

```powershell
# 1. 创建目录
mkdir C:\actions-runner
cd C:\actions-runner

# 2. 下载Runner（使用GitHub页面提供的最新链接）
Invoke-WebRequest -Uri https://github.com/actions/runner/releases/download/v2.xxx.x/actions-runner-win-x64-2.xxx.x.zip -OutFile actions-runner-win-x64-2.xxx.x.zip

# 3. 解压
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory("$PWD/actions-runner-win-x64-2.xxx.x.zip", "$PWD")

# 4. 配置Runner（使用GitHub页面提供的token）
.\config.cmd --url https://github.com/YOUR_USERNAME/YOUR_REPO --token YOUR_TOKEN

# 配置选项：
# - Runner name: IIS-Server-01 (或自定义名称)
# - Runner group: Default
# - Labels: self-hosted,windows,iis
# - Work folder: _work

# 5. 安装为Windows服务
.\svc.cmd install

# 6. 启动服务
.\svc.cmd start

# 7. 验证状态
.\svc.cmd status
```

### 3.4 在IIS服务器上执行（方式2：使用脚本）

如果你有GitHub Personal Access Token：

```powershell
# 在IIS服务器上下载项目中的安装脚本
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/scripts/install-runner.ps1" -OutFile "install-runner.ps1"

# 运行安装脚本
.\install-runner.ps1 `
    -GitHubToken "ghp_your_token_here" `
    -RepoUrl "https://github.com/YOUR_USERNAME/YOUR_REPO" `
    -RunnerName "IIS-Production-01" `
    -RunnerLabels "self-hosted,windows,iis,production"
```

### 3.5 验证Runner状态

在GitHub仓库中：
1. Settings > Actions > Runners
2. 应该看到你的Runner显示为 **Idle** (绿色)

---

## 第四步：触发自动部署

### 4.1 方式1：推送代码触发

```powershell
# 在本地修改任意文件
echo "# Test" >> README.md

# 提交并推送
git add .
git commit -m "测试自动部署"
git push origin main
```

### 4.2 方式2：手动触发

1. 访问GitHub仓库
2. 点击 **Actions** 标签
3. 选择 **Manual Deploy** 工作流
4. 点击 **Run workflow**
5. 选择参数：
   - Environment: `production`
   - Version: 留空（使用最新）
   - Skip tests: 不勾选
6. 点击 **Run workflow** 确认

### 4.3 监控部署过程

1. 在 **Actions** 页面查看工作流运行状态
2. 点击运行中的工作流查看详细日志
3. 等待部署完成（通常1-3分钟）

---

## 第五步：验证部署结果

### 5.1 检查GitHub Actions

- ✅ 工作流状态显示绿色勾号
- ✅ 所有步骤都成功完成
- ✅ 健康检查通过

### 5.2 检查IIS服务器

在IIS服务器上执行：

```powershell
# 检查站点状态
Import-Module WebAdministration
Get-Website | Where-Object { $_.Name -eq "Default Web Site" }

# 检查文件是否部署
dir C:\inetpub\wwwroot

# 应该看到：
# - index.html
# - dashboard.html
# - style.css
# - app.js
# - web.config
```

### 5.3 访问网站

打开浏览器访问你的IIS服务器地址，测试登录功能：
- 用户名: `admin` / 密码: `admin123`
- 用户名: `user` / 密码: `user123`

---

## 常见问题排查

### ❌ 问题1：Runner无法连接到GitHub

**解决方案：**
```powershell
# 测试网络连接
Test-NetConnection github.com -Port 443

# 如果有代理，配置代理
cd C:\actions-runner
Add-Content -Path ".env" -Value "HTTPS_PROXY=http://proxy:8080"

# 重启服务
.\svc.cmd stop
.\svc.cmd start
```

### ❌ 问题2：部署时权限不足

**解决方案：**
```powershell
# 检查Runner服务账户
Get-Service "actions.runner.*" | Select-Object Name, StartName

# 授予IIS目录权限
icacls "C:\inetpub\wwwroot" /grant "NT AUTHORITY\NETWORK SERVICE:(OI)(CI)F" /T
```

### ❌ 问题3：工作流找不到Runner

**解决方案：**
- 检查Runner标签是否匹配
- 确保Runner状态为 Idle
- 检查工作流中的 `runs-on: self-hosted`

### ❌ 问题4：健康检查失败

**解决方案：**
```powershell
# 检查IIS站点是否启动
Get-Website

# 启动站点
Start-Website -Name "Default Web Site"

# 测试本地访问
Invoke-WebRequest -Uri "http://localhost" -UseBasicParsing
```

---

## 🎉 部署成功检查清单

- [ ] Git仓库已创建并推送代码
- [ ] GitHub Secrets已配置（4个）
- [ ] Self-hosted Runner已安装并运行
- [ ] Runner在GitHub中显示为Idle状态
- [ ] 工作流已成功运行
- [ ] IIS站点文件已更新
- [ ] 网站可以正常访问
- [ ] 登录功能正常工作

---

## 下一步优化

完成基础部署后，可以考虑：

1. **配置多环境**
   - 开发环境（develop分支）
   - 预发布环境（staging分支）
   - 生产环境（main分支）

2. **添加通知**
   - Slack通知
   - 邮件通知
   - Teams通知

3. **增强安全**
   - 使用HTTPS
   - 配置防火墙
   - 启用日志审计

4. **性能优化**
   - 启用IIS压缩
   - 配置缓存策略
   - CDN加速

5. **监控告警**
   - 应用性能监控
   - 错误日志收集
   - 自动告警机制
