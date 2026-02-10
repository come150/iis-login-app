// 模拟用户数据库
const users = [
    { username: 'admin', password: 'admin123', role: '管理员' },
    { username: 'user', password: 'user123', role: '普通用户' }
];

// 获取表单元素
const loginForm = document.getElementById('loginForm');
const messageDiv = document.getElementById('message');

// 显示消息
function showMessage(text, type) {
    messageDiv.textContent = text;
    messageDiv.className = `message ${type}`;
    
    // 3秒后自动隐藏
    setTimeout(() => {
        messageDiv.style.display = 'none';
    }, 3000);
}

// 验证登录
function validateLogin(username, password) {
    const user = users.find(u => u.username === username && u.password === password);
    return user;
}

// 处理表单提交
loginForm.addEventListener('submit', function(e) {
    e.preventDefault();
    
    const username = document.getElementById('username').value.trim();
    const password = document.getElementById('password').value;
    
    // 验证输入
    if (!username || !password) {
        showMessage('请输入用户名和密码', 'error');
        return;
    }
    
    // 验证登录
    const user = validateLogin(username, password);
    
    if (user) {
        showMessage(`登录成功！欢迎 ${user.role} ${user.username}`, 'success');
        
        // 保存登录状态
        localStorage.setItem('currentUser', JSON.stringify({
            username: user.username,
            role: user.role,
            loginTime: new Date().toISOString()
        }));
        
        // 2秒后跳转到主页
        setTimeout(() => {
            window.location.href = 'dashboard.html';
        }, 2000);
    } else {
        showMessage('用户名或密码错误', 'error');
        document.getElementById('password').value = '';
    }
});

// 页面加载时检查是否已登录
window.addEventListener('load', function() {
    const currentUser = localStorage.getItem('currentUser');
    if (currentUser) {
        const user = JSON.parse(currentUser);
        showMessage(`您已登录为 ${user.username}`, 'success');
    }
});
