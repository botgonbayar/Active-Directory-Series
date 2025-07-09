function Get-SystemHealthReport {
    param(
        [string[]]$ComputerNames = @("localhost"),
        [string]$OutputPath = "C:\Reports\SystemHealth_$(Get-Date -Format 'yyyyMMdd').html"
    )
    
    $HealthReport = @()
    
    foreach ($Computer in $ComputerNames) {
        try {
            Write-Host "Checking system health for $Computer..." -ForegroundColor Yellow
            
            # Get system information
            $OS = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $Computer
            $Computer_Info = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $Computer
            $Disk = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $Computer | Where-Object {$_.DriveType -eq 3}
            
            # Calculate uptime
            $Uptime = (Get-Date) - $OS.ConvertToDateTime($OS.LastBootUpTime)
            
            # Check disk space
            $DiskAlerts = @()
            foreach ($Drive in $Disk) {
                $FreePercent = [math]::Round(($Drive.FreeSpace / $Drive.Size) * 100, 2)
                if ($FreePercent -lt 10) {
                    $DiskAlerts += "CRITICAL: Drive $($Drive.DeviceID) only $FreePercent% free"
                } elseif ($FreePercent -lt 20) {
                    $DiskAlerts += "WARNING: Drive $($Drive.DeviceID) only $FreePercent% free"
                }
            }
            
            # Check services
            $CriticalServices = @("Spooler", "BITS", "Winmgmt", "EventLog")
            $ServiceAlerts = @()
            foreach ($ServiceName in $CriticalServices) {
                $Service = Get-Service -Name $ServiceName -ComputerName $Computer -ErrorAction SilentlyContinue
                if ($Service.Status -ne "Running") {
                    $ServiceAlerts += "CRITICAL: Service $ServiceName is $($Service.Status)"
                }
            }
            
            # Check Windows Updates
            $UpdateSession = New-Object -ComObject Microsoft.Update.Session
            $UpdateSearcher = $UpdateSession.CreateUpdateSearcher()
            $SearchResult = $UpdateSearcher.Search("IsInstalled=0")
            $PendingUpdates = $SearchResult.Updates.Count
            
            # Determine overall health status
            $HealthStatus = "Healthy"
            if ($DiskAlerts.Count -gt 0 -or $ServiceAlerts.Count -gt 0) {
                $HealthStatus = "Warning"
            }
            if ($Uptime.Days -gt 30 -or $PendingUpdates -gt 20) {
                $HealthStatus = "Attention Required"
            }
            
            $SystemHealth = [PSCustomObject]@{
                ComputerName = $Computer
                Status = $HealthStatus
                LastBootTime = $OS.ConvertToDateTime($OS.LastBootUpTime)
                UptimeDays = $Uptime.Days
                TotalMemoryGB = [math]::Round($Computer_Info.TotalPhysicalMemory / 1GB, 2)
                OSVersion = $OS.Caption
                DiskAlerts = $DiskAlerts -join "; "
                ServiceAlerts = $ServiceAlerts -join "; "
                PendingUpdates = $PendingUpdates
                LastChecked = Get-Date
            }
            
            $HealthReport += $SystemHealth
            
        } catch {
            Write-Error "Failed to get health info for $Computer : $_"
        }
    }
    
    # Generate HTML report
    $HTML = @"
<!DOCTYPE html>
<html>
<head>
    <title>System Health Report - $(Get-Date -Format 'yyyy-MM-dd HH:mm')</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .healthy { background-color: #d4edda; }
        .warning { background-color: #fff3cd; }
        .critical { background-color: #f8d7da; }
    </style>
</head>
<body>
    <h1>System Health Report</h1>
    <p>Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
    
    <table>
        <tr>
            <th>Computer</th>
            <th>Status</th>
            <th>Uptime (Days)</th>
            <th>Memory (GB)</th>
            <th>OS Version</th>
            <th>Pending Updates</th>
            <th>Alerts</th>
        </tr>
"@
    
    foreach ($System in $HealthReport) {
        $RowClass = switch ($System.Status) {
            "Healthy" { "healthy" }
            "Warning" { "warning" }
            "Attention Required" { "critical" }
            default { "" }
        }
        
        $AllAlerts = @($System.DiskAlerts, $System.ServiceAlerts) | Where-Object {$_ -ne ""} | Join-String -Separator "; "
        
        $HTML += @"
        <tr class="$RowClass">
            <td>$($System.ComputerName)</td>
            <td>$($System.Status)</td>
            <td>$($System.UptimeDays)</td>
            <td>$($System.TotalMemoryGB)</td>
            <td>$($System.OSVersion)</td>
            <td>$($System.PendingUpdates)</td>
            <td>$AllAlerts</td>
        </tr>
"@
    }
    
    $HTML += @"
    </table>
</body>
</html>
"@
    
    $HTML | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Health report saved to: $OutputPath" -ForegroundColor Green
    
    return $HealthReport
}
