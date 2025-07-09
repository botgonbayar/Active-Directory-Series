function Start-SecureBackup {
    param(
        [string[]]$SourcePaths = @("C:\PatientData", "C:\Medical Records"),
        [string]$BackupDestination = "D:\Backups\$(Get-Date -Format 'yyyyMMdd_HHmmss')",
        [string]$EncryptionKey = "MedicalBackup2024!",
        [int]$RetentionDays = 30,
        [string]$LogPath = "C:\Logs\Backup.log"
    )
    
    function Write-BackupLog {
        param([string]$Message)
        $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        "$TimeStamp - $Message" | Add-Content -Path $LogPath
        Write-Host "$TimeStamp - $Message" -ForegroundColor Cyan
    }
    
    Write-BackupLog "Starting secure backup process"
    
    # Create backup directory
    if (!(Test-Path $BackupDestination)) {
        New-Item -ItemType Directory -Path $BackupDestination -Force | Out-Null
    }
    
    # Backup each source path
    foreach ($SourcePath in $SourcePaths) {
        if (Test-Path $SourcePath) {
            Write-BackupLog "Backing up: $SourcePath"
            $DestPath = Join-Path $BackupDestination (Split-Path $SourcePath -Leaf)
            
            try {
                # Copy files
                robocopy $SourcePath $DestPath /E /XO /R:3 /W:10 /LOG+:$LogPath
                
                # Compress and encrypt
                $ZipPath = "$DestPath.zip"
                Compress-Archive -Path $DestPath -DestinationPath $ZipPath -Force
                
                # Simple encryption (for production, use proper encryption tools)
                $EncryptedPath = "$ZipPath.encrypted"
                $SecureString = ConvertTo-SecureString -String $EncryptionKey -AsPlainText -Force
                $ZipContent = Get-Content -Path $ZipPath -Raw
                $EncryptedContent = ConvertFrom-SecureString -SecureString (ConvertTo-SecureString -String $ZipContent -AsPlainText -Force) -Key (1..16)
                Set-Content -Path $EncryptedPath -Value $EncryptedContent
                
                # Remove unencrypted files
                Remove-Item -Path $DestPath -Recurse -Force
                Remove-Item -Path $ZipPath -Force
                
                Write-BackupLog "Completed backup of: $SourcePath"
            }
            catch {
                Write-BackupLog "ERROR backing up $SourcePath : $($_.Exception.Message)"
            }
        }
        else {
            Write-BackupLog "WARNING: Source path not found: $SourcePath"
        }
    }
    
    # Cleanup old backups
    $BackupRoot = Split-Path $BackupDestination
    $OldBackups = Get-ChildItem -Path $BackupRoot -Directory | Where-Object { 
        $_.CreationTime -lt (Get-Date).AddDays(-$RetentionDays) 
    }
    
    foreach ($OldBackup in $OldBackups) {
        Write-BackupLog "Removing old backup: $($OldBackup.Name)"
        Remove-Item -Path $OldBackup.FullName -Recurse -Force
    }
    
    Write-BackupLog "Backup process completed"
}

# =====================================================
# Script 5: Access Control and Permission Auditing
# =====================================================

function Get-AccessControlAudit {
    param(
        [string[]]$FolderPaths = @("C:\PatientData", "C:\Medical Records"),
        [string]$OutputPath = "C:\Audit\Access_Control_$(Get-Date -Format 'yyyyMMdd').csv"
    )
    
    $AuditResults = @()
    
    foreach ($FolderPath in $FolderPaths) {
        if (Test-Path $FolderPath) {
            Write-Host "Auditing permissions for: $FolderPath" -ForegroundColor Yellow
            
            Get-ChildItem -Path $FolderPath -Recurse -Force | ForEach-Object {
                try {
                    $Acl = Get-Acl -Path $_.FullName
                    
                    foreach ($AccessRule in $Acl.Access) {
                        $AuditResults += [PSCustomObject]@{
                            Path = $_.FullName
                            Type = if ($_.PSIsContainer) { "Folder" } else { "File" }
                            Identity = $AccessRule.IdentityReference
                            Rights = $AccessRule.FileSystemRights
                            AccessType = $AccessRule.AccessControlType
                            Inherited = $AccessRule.IsInherited
                            LastModified = $_.LastWriteTime
                            Owner = $Acl.Owner
                        }
                    }
                }
                catch {
                    Write-Warning "Could not audit: $($_.FullName)"
                }
            }
        }
    }
    
    # Export results
    $AuditResults | Export-Csv -Path $OutputPath -NoTypeInformation
    
    # Generate summary
    $Summary = @{
        TotalItems = $AuditResults.Count
        UniqueUsers = ($AuditResults | Select-Object -ExpandProperty Identity | Sort-Object -Unique).Count
        FullControlAccess = ($AuditResults | Where-Object { $_.Rights -match "FullControl" }).Count
        ExternalAccess = ($AuditResults | Where-Object { $_.Identity -notmatch "DOMAIN\\" }).Count
    }
    
    Write-Host "Access Control Audit Summary:" -ForegroundColor Green
    Write-Host "Total Items Audited: $($Summary.TotalItems)" -ForegroundColor White
    Write-Host "Unique Users with Access: $($Summary.UniqueUsers)" -ForegroundColor White
    Write-Host "Full Control Permissions: $($Summary.FullControlAccess)" -ForegroundColor White
    Write-Host "External Access Entries: $($Summary.ExternalAccess)" -ForegroundColor Yellow
    Write-Host "Report saved to: $OutputPath" -ForegroundColor Green
}
