using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting; // 必须引用
using Moq; // 建议安装 NuGet 包: Moq
using Quant.Infra.Net.Notification.Model;
using Quant.Infra.Net.Notification.Service;

namespace Quant.Infra.Net.Tests
{
	[TestClass]
	public class EmailIntegrationTests
	{
		private EmailServiceFactory _factory;
		private IConfiguration _config;
		private IServiceProvider _serviceProvider; // 提升为成员变量以便直接获取服务
		private string _testRecipient = "yuanyuancomecome@outlook.com";

		[TestInitialize]
		public void Setup()
		{
			// 1. 加载配置
			_config = new ConfigurationBuilder()
				.AddJsonFile("appsettings.test.json", optional: true)
				.AddUserSecrets<EmailIntegrationTests>()
				.Build();

			// 2. 模拟生产环境的 DI 容器注册
			var services = new ServiceCollection();

			// --- 关键修改：模拟并注册 IHostEnvironment ---
			var mockEnv = new Mock<IHostEnvironment>();
			mockEnv.Setup(m => m.EnvironmentName).Returns("Development");
			mockEnv.Setup(m => m.ContentRootPath).Returns(AppDomain.CurrentDomain.BaseDirectory);
			services.AddSingleton(mockEnv.Object);

			// 注册具体的实现类
			services.AddTransient<PersonalEmailService>();
			services.AddTransient<CommercialEmailService>();

			// 将 IConfiguration 注入容器
			services.AddSingleton(_config);

			_serviceProvider = services.BuildServiceProvider();

			// 3. 初始化工厂
			_factory = new EmailServiceFactory(_serviceProvider, _config);
		}

		[TestMethod]
		public async Task MVP_PersonalSendTest_ViaFactory()
		{
			// Arrange
			var recipients = new List<string> { _testRecipient };
			var message = new EmailMessage
			{
				To = recipients,
				Subject = $"MVP Factory Test - {DateTime.Now:HH:mm}",
				Body = "<h1>MVP 发送测试</h1><p>通过 EmailServiceFactory 路由至 PersonalEmailService 发送。</p>",
				IsHtml = true
			};

			var emailConfig = _config.GetSection("Email");
			var personalConfig = emailConfig.GetSection("Personal");

			var settings = new PersonalEmailSetting
			{
				SmtpServer = personalConfig["SmtpServer"] ?? "smtp.126.com",
				Port = int.Parse(personalConfig["Port"] ?? "465"),
				SenderEmail = personalConfig["SenderEmail"] ?? "test@126.com",
				Password = personalConfig["Password"] ?? "test-password",
				SenderName = personalConfig["SenderName"] ?? "Test Sender"
			};

			// Act
			var service = _factory.GetService(recipients.Count);

			// Assert
			Assert.IsInstanceOfType(service, typeof(PersonalEmailService));
			var result = await service.SendBulkEmailAsync(message, settings);
			Assert.IsTrue(result);
		}

		[TestMethod]
		public async Task MVP_SendCommercial()
		{
			// Arrange
			var recipients = new List<string> { _testRecipient, "rong.fan1031@gmail.com" };

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
                <p><strong>发送方式：</strong>GitHub Actions 自动化测试</p>
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

			var emailConfig = _config.GetSection("Email");
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

			// Act 
			// --- 关键修改：从 DI 容器获取服务，而不是 new ---
			var service = _serviceProvider.GetRequiredService<CommercialEmailService>();

			// 验证逻辑
			Console.WriteLine($"✅ 使用由 DI 容器注入 IHostEnvironment 的 CommercialEmailService");

			if (settings.Password.StartsWith("xkeysib-"))
			{
				Assert.Fail("检测到 API Key，但该测试需要 SMTP 凭据 (xsmtpsib-...)");
			}

			// 2. 调用真实发送
			try
			{
				var result = await service.SendBulkEmailAsync(message, settings);
				Assert.IsTrue(result, "Brevo 真实邮件发送失败");
			}
			catch (Exception ex)
			{
				Console.WriteLine($"❌ 异常: {ex.Message}");
				throw;
			}
		}
	}
}