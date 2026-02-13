using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Hosting;
using Quant.Infra.Net.Notification.Model;
using Quant.Infra.Net.Notification.Service;

namespace Quant.Infra.Net.EmailSender
{
    class Program
    {
        static async Task<int> Main(string[] args)
        {
            Console.WriteLine("========================================");
            Console.WriteLine("  Quant.Infra.Net 邮件发送工具");
            Console.WriteLine("========================================");
            Console.WriteLine();

            try
            {
                // 1. 加载配置
                var config = new ConfigurationBuilder()
                    .AddJsonFile("appsettings.json", optional: true)
                    .AddUserSecrets<Program>()
                    .Build();

                // 2. 设置 DI 容器
                var services = new ServiceCollection();

                // 模拟 IHostEnvironment
                var mockEnv = new MockHostEnvironment
                {
                    EnvironmentName = "Production",
                    ContentRootPath = AppDomain.CurrentDomain.BaseDirectory
                };
                services.AddSingleton<IHostEnvironment>(mockEnv);

                // 注册服务
                services.AddTransient<CommercialEmailService>();
                services.AddSingleton<IConfiguration>(config);

                var serviceProvider = services.BuildServiceProvider();

                // 3. 准备邮件内容
                var recipients = new List<string> { "yuanyuancomecome@outlook.com", "rong.fan1031@gmail.com" };

                var message = new EmailMessage
                {
                    To = recipients,
                    Subject = $"🎯 量化交易系统邮件测试 - {DateTime.Now:yyyy-MM-dd HH:mm:ss}",
                    Body = @"
<!DOCTYPE html>
<html>
<head>
    <meta charset='utf-8'>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .highlight { background: #fff; padding: 15px; border-left: 4px solid #667eea; margin: 20px 0; }
        .footer { text-align: center; margin-top: 30px; color: #666; font-size: 12px; }
        .button { display: inline-block; padding: 12px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 5px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class='container'>
        <div class='header'>
            <h1>🎯 量化交易系统</h1>
            <p>邮件发送功能测试</p>
        </div>
        <div class='content'>
            <h2>测试信息</h2>
            <div class='highlight'>
                <p><strong>测试时间：</strong>" + DateTime.Now.ToString("yyyy-MM-dd HH:mm:ss") + @"</p>
                <p><strong>测试类型：</strong>Commercial Email Service (Brevo SMTP)</p>
                <p><strong>发送方式：</strong>GitHub Actions 自动化测试 - Console App</p>
            </div>
            
            <h3>✅ 测试目的</h3>
            <p>验证 Quant.Infra.Net 邮件服务在 GitHub Actions 环境中的功能：</p>
            <ul>
                <li>✓ 验证 SMTP 配置正确性</li>
                <li>✓ 验证 User Secrets 配置</li>
                <li>✓ 验证邮件发送功能</li>
                <li>✓ 验证 HTML 邮件格式</li>
            </ul>
            
            <h3>📊 系统状态</h3>
            <p>所有系统组件运行正常，邮件服务已就绪。</p>
            
            <div style='text-align: center;'>
                <a href='https://github.com/come150/iis-login-app' class='button'>查看 GitHub 仓库</a>
            </div>
        </div>
        <div class='footer'>
            <p>此邮件由 Quant.Infra.Net 自动发送</p>
            <p>Powered by Brevo SMTP Service</p>
        </div>
    </div>
</body>
</html>",
                    IsHtml = true
                };

                // 4. 加载邮件配置
                var emailConfig = config.GetSection("Email");
                var commercialConfig = emailConfig.GetSection("Commercial");

                var settings = new CommercialEmailSetting
                {
                    SmtpServer = commercialConfig["SmtpServer"] ?? "smtp-relay.brevo.com",
                    Port = int.Parse(commercialConfig["Port"] ?? "587"),
                    Username = commercialConfig["Username"] ?? "",
                    Password = commercialConfig["Password"] ?? throw new InvalidOperationException("Brevo SMTP Key not found"),
                    SenderEmail = commercialConfig["SenderEmail"] ?? "yuanhw512@gmail.com",
                    SenderName = commercialConfig["SenderName"] ?? "Quant Lab System"
                };
                settings.SenderEmail = settings.SenderEmail.ToLower();

                // 5. 显示配置信息
                Console.WriteLine("配置信息:");
                Console.WriteLine($"  SMTP Server: {settings.SmtpServer}:{settings.Port}");
                Console.WriteLine($"  Username: {settings.Username}");
                Console.WriteLine($"  Password: {settings.Password?.Substring(0, Math.Min(15, settings.Password.Length))}...");
                Console.WriteLine($"  Sender: {settings.SenderEmail}");
                Console.WriteLine($"  Recipients: {string.Join(", ", message.To)}");
                Console.WriteLine();

                // 6. 验证密钥格式
                if (settings.Password.StartsWith("xkeysib-"))
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine("❌ 检测到 API Key (xkeysib-)，但需要 SMTP 密钥 (xsmtpsib-)");
                    Console.ResetColor();
                    return 1;
                }
                else if (settings.Password.StartsWith("xsmtpsib-"))
                {
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine("✓ 检测到正确的 SMTP 密钥 (xsmtpsib-)");
                    Console.ResetColor();
                }
                else
                {
                    Console.ForegroundColor = ConsoleColor.Yellow;
                    Console.WriteLine("⚠ 未识别的密钥格式");
                    Console.ResetColor();
                }

                Console.WriteLine();

                // 7. 发送邮件
                var service = serviceProvider.GetRequiredService<CommercialEmailService>();
                Console.WriteLine("开始发送邮件...");
                Console.WriteLine();

                var result = await service.SendBulkEmailAsync(message, settings);

                Console.WriteLine();
                if (result)
                {
                    Console.ForegroundColor = ConsoleColor.Green;
                    Console.WriteLine("========================================");
                    Console.WriteLine("  ✓ 邮件发送成功！");
                    Console.WriteLine("========================================");
                    Console.ResetColor();
                    return 0;
                }
                else
                {
                    Console.ForegroundColor = ConsoleColor.Red;
                    Console.WriteLine("========================================");
                    Console.WriteLine("  ✗ 邮件发送失败");
                    Console.WriteLine("========================================");
                    Console.ResetColor();
                    return 1;
                }
            }
            catch (Exception ex)
            {
                Console.ForegroundColor = ConsoleColor.Red;
                Console.WriteLine();
                Console.WriteLine("========================================");
                Console.WriteLine("  ✗ 发生错误");
                Console.WriteLine("========================================");
                Console.WriteLine($"错误信息: {ex.Message}");
                Console.WriteLine($"错误类型: {ex.GetType().Name}");
                Console.WriteLine($"堆栈跟踪: {ex.StackTrace}");
                Console.ResetColor();
                return 1;
            }
        }
    }

    // 简单的 IHostEnvironment 实现
    public class MockHostEnvironment : IHostEnvironment
    {
        public string EnvironmentName { get; set; } = "Production";
        public string ApplicationName { get; set; } = "Quant.Infra.Net.EmailSender";
        public string ContentRootPath { get; set; } = "";
        public IFileProvider ContentRootFileProvider { get; set; } = null!;
    }
}
