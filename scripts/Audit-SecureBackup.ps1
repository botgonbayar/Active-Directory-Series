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
