const fs = require('fs');
const path = require('path');

// 创建dist目录
const distDir = path.join(__dirname, 'dist');
if (!fs.existsSync(distDir)) {
    fs.mkdirSync(distDir, { recursive: true });
}

// 复制src目录下的所有文件到dist
const srcDir = path.join(__dirname, 'src');
const files = fs.readdirSync(srcDir);

console.log('开始构建...');

files.forEach(file => {
    const srcFile = path.join(srcDir, file);
    const distFile = path.join(distDir, file);
    
    fs.copyFileSync(srcFile, distFile);
    console.log(`✓ 复制: ${file}`);
});

console.log('构建完成！输出目录: dist/');
