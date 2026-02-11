# 推送代码到GitHub

## 方法1：解决网络连接问题

### 如果你在中国大陆，可能需要配置代理：

```powershell
# 如果你有代理（例如VPN或代理软件）
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890

# 然后重试推送
git push -u origin main

# 推送成功后，可以取消代理设置
git config --global --unset http.proxy
git config --global --unset https.proxy
```

### 或者使用SSH方式：

```powershell
# 1. 检查是否有SSH密钥
ls ~/.ssh

# 2. 如果没有，生成SSH密钥
ssh-keygen -t ed25519 -C "your_email@example.com"
# 一路回车

# 3. 复制公钥
cat ~/.ssh/id_ed25519.pub

# 4. 添加到GitHub
# 访问: https://github.com/settings/keys
# 点击 "New SSH key"
# 粘贴公钥内容

# 5. 更改远程仓库URL为SSH
git remote set-url origin git@github.com:come150/iis-login-app.git

# 6. 推送
git push -u origin main
```

## 方法2：使用GitHub Desktop（最简单）

1. 下载安装 GitHub Desktop: https://desktop.github.com/
2. 打开 GitHub Desktop
3. File > Add Local Repository
4. 选择当前目录: `E:\github\GitHub Self-hosted Runner`
5. 点击 "Publish repository"
6. 选择账号 come150
7. Repository name: iis-login-app
8. 点击 "Publish repository"

## 方法3：使用Git Credential Manager

```powershell
# 清除旧的凭据
git credential-manager-core erase https://github.com

# 重新推送（会弹出登录窗口）
git push -u origin main
```

## 方法4：使用Personal Access Token

```powershell
# 1. 创建Token
# 访问: https://github.com/settings/tokens
# 点击 "Generate new token (classic)"
# 勾选 "repo" 权限
# 生成并复制Token

# 2. 使用Token推送
git remote set-url origin https://YOUR_TOKEN@github.com/come150/iis-login-app.git
git push -u origin main

# 3. 推送成功后，改回普通URL（安全考虑）
git remote set-url origin https://github.com/come150/iis-login-app.git
```

## 验证推送成功

推送成功后，访问：
```
https://github.com/come150/iis-login-app
```

你应该能看到所有文件，包括：
- .github/workflows/
- src/
- scripts/
- README.md
- 等等

## 推送成功后的下一步

### 1. 配置GitHub Secrets

访问: https://github.com/come150/iis-login-app/settings/secrets/actions

点击 "New repository secret"，添加4个Secrets：

**Secret 1:**
- Name: `IIS_SITE_NAME`
- Value: `Default Web Site` (你的IIS站点名称)

**Secret 2:**
- Name: `IIS_SITE_PATH`
- Value: `C:\inetpub\wwwroot` (你的站点路径)

**Secret 3:**
- Name: `BACKUP_PATH`
- Value: `C:\IISBackups`

**Secret 4:**
- Name: `HEALTH_CHECK_URL`
- Value: `http://localhost` (或你的服务器地址)

### 2. 在IIS服务器上安装Self-hosted Runner

访问: https://github.com/come150/iis-login-app/settings/actions/runners/new

选择 Windows x64，按照页面指引操作。

### 3. 触发部署

推送任何代码更改：
```powershell
echo "# Update" >> README.md
git add .
git commit -m "测试部署"
git push origin main
```

或手动触发：
- 访问: https://github.com/come150/iis-login-app/actions
- 选择 "Manual Deploy"
- 点击 "Run workflow"
