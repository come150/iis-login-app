param(
    [Parameter(Mandatory=$true)]
    [string]$SiteName,
    
    [Parameter(Mandatory=$true)]
    [string]$SitePath,
    
    [Parameter(Mandatory=$true)]
    [string]$SourcePath,
    
    [Parameter(Mandatory=$false)]
    [switch]$EnableBackup,
    
    [Parameter(Mandatory=$false)]
    [string]$BackupPath = "C:\IISBackups"
)

Import-Module WebAdministration -ErrorAction Stop

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Level] $Message"
}

try {
    Write-Log "========== 开始部署 =========="
    Write-Log "站点: $SiteName"
    Write-Log "路径: $SitePath"
    
    # 获取应用程序池
    $site = Get-Website -Name $SiteName -ErrorAction Stop
    $appPoolName = $site.applicationPool
    Write-Log "应用程序池: $appPoolName"
    
    # 备份
    if ($EnableBackup) {
        Write-Log "创建备份..."
        $backupFolder = Join-Path $BackupPath "Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
        Copy-Item -Path "$SitePath\*" -Destination $backupFolder -Recurse -Force
        Write-Log "备份完成: $backupFolder"
    }
    
    # 停止服务
    Write-Log "停止应用程序池..."
    Stop-WebAppPool -Name $appPoolName
    Start-Sleep -Seconds 3
    
    Write-Log "停止站点..."
    Stop-Website -Name $SiteName
    Start-Sleep -Seconds 2
    
    # 保留配置文件
    $webConfig = Join-Path $SitePath "web.config"
    $tempConfig = "$env:TEMP\web.config.$(Get-Date -Format 'yyyyMMddHHmmss')"
    
    if (Test-Path $webConfig) {
        Copy-Item $webConfig $tempConfig -Force
        Write-Log "已保存 web.config"
    }
    
    # 清理并部署
    Write-Log "清理旧文件..."
    Get-ChildItem -Path $SitePath | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    
    Write-Log "复制新文件..."
    Copy-Item -Path "$SourcePath\*" -Destination $SitePath -Recurse -Force
    
    # 恢复配置
    if (Test-Path $tempConfig) {
        Copy-Item $tempConfig $webConfig -Force
        Remove-Item $tempConfig -Force
        Write-Log "已恢复 web.config"
    }
    
    # 启动服务
    Write-Log "启动站点..."
    Start-Website -Name $SiteName
    Start-Sleep -Seconds 2
    
    Write-Log "启动应用程序池..."
    Start-WebAppPool -Name $appPoolName
    Start-Sleep -Seconds 3
    
    # 验证
    $siteState = (Get-Website -Name $SiteName).state
    $poolState = (Get-WebAppPoolState -Name $appPoolName).Value
    
    if ($siteState -eq "Started" -and $poolState -eq "Started") {
        Write-Log "========== 部署成功 ==========" "SUCCESS"
        exit 0
    } else {
        throw "服务未正常启动"
    }
    
} catch {
    Write-Log "错误: $($_.Exception.Message)" "ERROR"
    
    # 尝试启动服务
    try {
        Start-Website -Name $SiteName -ErrorAction SilentlyContinue
        Start-WebAppPool -Name $appPoolName -ErrorAction SilentlyContinue
    } catch {}
    
    exit 1
}
