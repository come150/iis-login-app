# 快速开始 - 登录示例应用

这是一个最简单的用户登录示例，演示如何使用GitHub Actions自动部署到IIS。

## 项目结构

```
├── src/                    # 源代码目录
│   ├── index.html         # 登录页面
│   ├── dashboard.html     # 用户中心页面
│   ├── style.css          # 样式文件
│   ├── app.js             # 登录逻辑
│   └── web.config         # IIS配置文件
├── .github/workflows/     # GitHub Actions工作流
├── scripts/               # 部署脚本
├── build.js               # 构建脚本
└── server.js              # 本地开发服务器
```

## 本地测试

### 方式1：使用Node.js服务器

```bash
# 安装依赖（如果需要）
npm install

# 启动开发服务器
npm start

# 访问 http://localhost:3000
```

### 方式2：直接打开HTML文件

```bash
# 在浏览器中打开
src/index.html
```

## 测试账号

- **管理员账号**
  - 用户名: `admin`
  - 密码: `admin123`

- **普通用户账号**
  - 用户名: `user`
  - 密码: `user123`

## 部署到IIS

### 前提条件

1. 已安装并配置好GitHub Self-hosted Runner（参考SETUP-GUIDE.md）
2. 已在GitHub仓库中配置好Secrets：
   - `IIS_SITE_NAME`: 你的IIS站点名称
   - `IIS_SITE_PATH`: 站点物理路径
   - `BACKUP_PATH`: 备份目录
   - `HEALTH_CHECK_URL`: 健康检查URL

### 自动部署

1. **提交代码到GitHub**

```bash
git add .
git commit -m "初始化登录应用"
git push origin main
```

2. **自动触发部署**

推送到`main`分支后，GitHub Actions会自动：
- 构建项目（复制src到dist）
- 下载构建产物到Self-hosted Runner
- 停止IIS站点
- 备份当前版本
- 部署新版本
- 启动IIS站点
- 执行健康检查

3. **查看部署状态**

访问GitHub仓库 > Actions，查看工作流运行状态。

### 手动部署

如果需要手动触发部署：

1. 访问GitHub仓库 > Actions
2. 选择 "Manual Deploy" 工作流
3. 点击 "Run workflow"
4. 选择环境和参数
5. 点击 "Run workflow" 确认

## 本地构建测试

```bash
# 构建项目
npm run build

# 查看构建产物
dir dist
# 或
ls dist/
```

构建后的文件在`dist/`目录中，包含：
- index.html
- dashboard.html
- style.css
- app.js
- web.config

## IIS配置说明

### 创建新站点

```powershell
# 以管理员身份运行PowerShell

Import-Module WebAdministration

# 创建应用程序池
New-WebAppPool -Name "LoginAppPool"

# 创建站点
New-Website -Name "LoginApp" `
    -PhysicalPath "C:\inetpub\wwwroot\loginapp" `
    -ApplicationPool "LoginAppPool" `
    -Port 80

# 启动站点
Start-Website -Name "LoginApp"
```

### 配置现有站点

```powershell
# 停止站点
Stop-Website -Name "Default Web Site"

# 清空目录
Remove-Item "C:\inetpub\wwwroot\*" -Recurse -Force

# 复制文件
Copy-Item ".\dist\*" -Destination "C:\inetpub\wwwroot\" -Recurse -Force

# 启动站点
Start-Website -Name "Default Web Site"
```

## 功能说明

### 登录页面 (index.html)

- 用户名和密码输入
- 表单验证
- 登录成功/失败提示
- 自动跳转到用户中心
- 记住登录状态（localStorage）

### 用户中心 (dashboard.html)

- 显示用户信息
- 显示登录时间
- 退出登录功能
- 登录状态检查

### 安全特性

- XSS保护（X-XSS-Protection）
- 点击劫持保护（X-Frame-Options）
- MIME类型嗅探保护（X-Content-Type-Options）
- 自定义404错误页面

## 自定义修改

### 修改测试账号

编辑 `src/app.js`：

```javascript
const users = [
    { username: 'admin', password: 'admin123', role: '管理员' },
    { username: 'user', password: 'user123', role: '普通用户' },
    // 添加更多用户
    { username: 'test', password: 'test123', role: '测试用户' }
];
```

### 修改样式

编辑 `src/style.css` 修改颜色、布局等。

### 添加新页面

1. 在 `src/` 目录创建新的HTML文件
2. 在 `dashboard.html` 中添加链接
3. 重新构建和部署

## 故障排查

### 问题1：页面显示404

**解决方案：**
- 检查IIS站点是否启动
- 检查物理路径是否正确
- 检查web.config是否存在

### 问题2：样式不显示

**解决方案：**
- 检查CSS文件路径
- 检查IIS MIME类型配置
- 清除浏览器缓存

### 问题3：登录后跳转失败

**解决方案：**
- 检查dashboard.html是否存在
- 检查浏览器控制台错误
- 检查localStorage是否被禁用

### 问题4：部署失败

**解决方案：**
```powershell
# 检查Runner状态
Get-Service "actions.runner.*"

# 检查IIS状态
Get-Website
Get-WebAppPoolState -Name "YourAppPool"

# 查看部署日志
Get-Content "C:\actions-runner\_diag\Worker_*.log" -Tail 50
```

## 下一步

- [ ] 添加后端API（Node.js/ASP.NET）
- [ ] 连接真实数据库
- [ ] 添加用户注册功能
- [ ] 实现密码加密
- [ ] 添加JWT认证
- [ ] 实现多环境部署
- [ ] 添加自动化测试

## 参考资源

- [IIS配置文档](https://docs.microsoft.com/iis)
- [GitHub Actions文档](https://docs.github.com/actions)
- [Self-hosted Runner指南](./SETUP-GUIDE.md)
- [完整部署文档](./README.md)
