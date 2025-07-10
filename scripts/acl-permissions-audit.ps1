.DESCRIPTION
    This function recursively scans one or more folder paths, collects access control information 
    (like who has access, permission level, and inheritance), and saves everything into a CSV.
    It also prints a quick summary to the console — total audited items, unique users, full control entries, 
    and any potential external access.

.EXAMPLE
    # Run with custom folders and save report to D:\Reports
    Get-AccessControlAudit -FolderPaths "D:\HR", "D:\Finance" -OutputPath "D:\Reports\HR_Audit.csv"

.NOTES
    # Make sure you run this with appropriate permissions (e.g., as an admin) to access all subfolders.
    # Helpful for security audits, compliance checks, or spotting unexpected access.

function Get-AccessControlAudit {
    param(
        # List of folder paths you want to audit. You can add or remove paths as needed.
        [string[]]$FolderPaths = @("C:\PatientData", "C:\Medical Records"),
        # Where the final CSV report will be saved, includes today's date in the filename
        [string]$OutputPath = "C:\Audit\Access_Control_$(Get-Date -Format 'yyyyMMdd').csv"
    )
    
    $AuditResults = @()

    # Go through each folder in the list
    foreach ($FolderPath in $FolderPaths) {
        if (Test-Path $FolderPath) {
            Write-Host "Auditing permissions for: $FolderPath" -ForegroundColor Yellow

             # Recursively get all files and subfolders, including hidden/system items
            Get-ChildItem -Path $FolderPath -Recurse -Force | ForEach-Object {
                try {
                    $Acl = Get-Acl -Path $_.FullName

                     # For each access rule (who can do what), collect the info
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
    
     # Create a quick summary of the audit for the terminal
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
