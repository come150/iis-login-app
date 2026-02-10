# 测试指南

## 本地测试步骤

### 1. 启动本地服务器

```bash
# 方式1：使用Node.js
npm start

# 方式2：使用Python（如果已安装）
cd src
python -m http.server 8000

# 方式3：使用PowerShell（Windows）
cd src
python -m http.server 8000
```

### 2. 访问应用

打开浏览器访问：
- Node.js: http://localhost:3000
- Python: http://localhost:8000

### 3. 测试登录功能

#### 测试用例1：成功登录（管理员）
1. 输入用户名: `admin`
2. 输入密码: `admin123`
3. 点击"登录"按钮
4. **预期结果**: 显示"登录成功！欢迎 管理员 admin"
5. **预期结果**: 2秒后自动跳转到用户中心

#### 测试用例2：成功登录（普通用户）
1. 输入用户名: `user`
2. 输入密码: `user123`
3. 点击"登录"按钮
4. **预期结果**: 显示"登录成功！欢迎 普通用户 user"
5. **预期结果**: 2秒后自动跳转到用户中心

#### 测试用例3：登录失败（错误密码）
1. 输入用户名: `admin`
2. 输入密码: `wrongpassword`
3. 点击"登录"按钮
4. **预期结果**: 显示"用户名或密码错误"
5. **预期结果**: 密码框被清空

#### 测试用例4：登录失败（空输入）
1. 不输入任何内容
2. 点击"登录"按钮
3. **预期结果**: 浏览器显示"请填写此字段"提示

#### 测试用例5：用户中心访问
1. 成功登录后进入用户中心
2. **预期结果**: 显示用户名、角色、登录时间
3. **预期结果**: 显示"在线"状态

#### 测试用例6：退出登录
1. 在用户中心点击"退出登录"
2. 确认退出
3. **预期结果**: 跳转回登录页面
4. **预期结果**: localStorage中的用户信息被清除

#### 测试用例7：未登录访问用户中心
1. 清除浏览器localStorage
2. 直接访问 dashboard.html
3. **预期结果**: 弹出"请先登录"提示
4. **预期结果**: 自动跳转到登录页面

## 构建测试

```bash
# 运行构建
npm run build

# 检查dist目录
dir dist  # Windows
ls dist/  # Linux/Mac

# 预期结果：dist目录包含以下文件
# - index.html
# - dashboard.html
# - style.css
# - app.js
# - web.config
```

## IIS部署测试（本地）

### 前提条件
- 已安装IIS
- 已安装WebAdministration模块

### 测试步骤

```powershell
# 1. 构建项目
npm run build

# 2. 创建测试站点
Import-Module WebAdministration

$siteName = "LoginAppTest"
$sitePath = "C:\inetpub\wwwroot\logintest"
$port = 8080

# 创建目录
New-Item -ItemType Directory -Path $sitePath -Force

# 复制文件
Copy-Item ".\dist\*" -Destination $sitePath -Recurse -Force

# 创建应用程序池
New-WebAppPool -Name "${siteName}Pool"

# 创建站点
New-Website -Name $siteName `
    -PhysicalPath $sitePath `
    -ApplicationPool "${siteName}Pool" `
    -Port $port

# 启动站点
Start-Website -Name $siteName

Write-Host "测试站点已创建: http://localhost:$port" -ForegroundColor Green
```

### 验证IIS部署

1. 打开浏览器访问 http://localhost:8080
2. 执行上述所有登录测试用例
3. 检查IIS日志：`C:\inetpub\logs\LogFiles\`

### 清理测试站点

```powershell
# 停止并删除测试站点
Stop-Website -Name "LoginAppTest"
Remove-Website -Name "LoginAppTest"
Remove-WebAppPool -Name "LoginAppTestPool"
Remove-Item "C:\inetpub\wwwroot\logintest" -Recurse -Force
```

## GitHub Actions测试

### 测试工作流语法

```bash
# 安装act（本地运行GitHub Actions）
# Windows (使用Chocolatey)
choco install act-cli

# 或下载：https://github.com/nektos/act

# 运行工作流测试
act -l  # 列出所有工作流
act push  # 模拟push事件
```

### 测试Self-hosted Runner

```powershell
# 1. 检查Runner状态
Get-Service "actions.runner.*"

# 2. 查看Runner日志
Get-Content "C:\actions-runner\_diag\Runner_*.log" -Tail 50

# 3. 手动触发部署
# 访问GitHub仓库 > Actions > Manual Deploy > Run workflow

# 4. 监控部署过程
# 在GitHub Actions页面实时查看日志
```

## 性能测试

### 页面加载测试

```javascript
// 在浏览器控制台运行
console.time('页面加载');
window.addEventListener('load', () => {
    console.timeEnd('页面加载');
});

// 预期结果：< 1秒
```

### 登录响应测试

```javascript
// 在浏览器控制台运行
console.time('登录处理');
document.getElementById('loginForm').addEventListener('submit', (e) => {
    console.timeEnd('登录处理');
});

// 预期结果：< 100ms
```

## 浏览器兼容性测试

测试以下浏览器：
- ✅ Chrome (最新版)
- ✅ Edge (最新版)
- ✅ Firefox (最新版)
- ✅ Safari (最新版)
- ✅ IE 11 (如需支持)

## 安全测试

### XSS测试

尝试在用户名输入框输入：
```html
<script>alert('XSS')</script>
```

**预期结果**: 不执行脚本，作为普通文本处理

### SQL注入测试（虽然是前端验证）

尝试输入：
```
admin' OR '1'='1
```

**预期结果**: 登录失败（因为不匹配任何用户）

## 自动化测试脚本

创建 `test.js`：

```javascript
// 简单的自动化测试
const assert = require('assert');

// 模拟用户数据
const users = [
    { username: 'admin', password: 'admin123', role: '管理员' },
    { username: 'user', password: 'user123', role: '普通用户' }
];

function validateLogin(username, password) {
    return users.find(u => u.username === username && u.password === password);
}

// 测试用例
console.log('运行测试...');

// 测试1：正确的凭据
assert.ok(validateLogin('admin', 'admin123'), '测试1失败：管理员登录');
console.log('✓ 测试1通过：管理员登录');

// 测试2：错误的密码
assert.ok(!validateLogin('admin', 'wrong'), '测试2失败：错误密码');
console.log('✓ 测试2通过：错误密码');

// 测试3：不存在的用户
assert.ok(!validateLogin('hacker', 'password'), '测试3失败：不存在的用户');
console.log('✓ 测试3通过：不存在的用户');

// 测试4：空输入
assert.ok(!validateLogin('', ''), '测试4失败：空输入');
console.log('✓ 测试4通过：空输入');

console.log('\n所有测试通过！');
```

运行测试：
```bash
node test.js
```

## 测试检查清单

部署前确认：

- [ ] 本地服务器正常运行
- [ ] 所有登录测试用例通过
- [ ] 用户中心功能正常
- [ ] 退出登录功能正常
- [ ] 构建脚本成功执行
- [ ] dist目录包含所有必要文件
- [ ] web.config配置正确
- [ ] IIS本地部署测试通过
- [ ] 浏览器兼容性测试通过
- [ ] 安全测试通过
- [ ] GitHub Actions工作流语法正确
- [ ] Self-hosted Runner连接正常

## 故障排查

### 本地测试失败

```bash
# 检查Node.js版本
node --version

# 重新安装依赖
rm -rf node_modules
npm install

# 清除缓存
npm cache clean --force
```

### IIS测试失败

```powershell
# 检查IIS服务
Get-Service W3SVC

# 重启IIS
iisreset

# 检查站点状态
Get-Website
Get-WebAppPoolState -Name "YourAppPool"

# 查看IIS日志
Get-Content "C:\inetpub\logs\LogFiles\W3SVC1\*.log" -Tail 20
```

### 部署测试失败

```powershell
# 检查Runner
Get-Service "actions.runner.*"

# 重启Runner
Restart-Service "actions.runner.*"

# 查看详细日志
Get-Content "C:\actions-runner\_diag\Worker_*.log" -Tail 100
```
