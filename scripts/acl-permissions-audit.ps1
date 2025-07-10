<#
.SYNOPSIS
    Audits file and folder permissions (ACLs) on specified directories and exports the results to a CSV report.

.DESCRIPTION
    This function recursively scans one or more folder paths, collects access control information 
    (like who has access, permission level, and inheritance), and saves everything into a CSV.
    It also prints a quick summary to the console — total audited items, unique users, full control entries, 
    and any potential external access.

.PARAMETER FolderPaths
    One or more directories you'd like to audit. Defaults to:
    "C:\PatientData", "C:\Medical Records"

.PARAMETER OutputPath
    Full file path (including filename) where the CSV report should be saved.
    By default, it goes to: C:\Audit\Access_Control_<date>.csv

.EXAMPLE
    # Run with default folders and output location
    Get-AccessControlAudit

.EXAMPLE
    # Run with custom folders and save report to D:\Reports
    Get-AccessControlAudit -FolderPaths "D:\HR", "D:\Finance" -OutputPath "D:\Reports\HR_Audit.csv"

.NOTES
    - Make sure you run this with appropriate permissions (e.g., as an admin) to access all subfolders.
    - Helpful for security audits, compliance checks, or spotting unexpected access.

# Define a custom PowerShell function called "Get-AccessControlAudit"
function Get-AccessControlAudit {
    param(
        # List of folder paths you want to audit. You can add or remove paths as needed.
        [string[]]$FolderPaths = @("C:\PatientData", "C:\Medical Records"),

        # Where the final CSV report will be saved, includes today's date in the filename
        [string]$OutputPath = "C:\Audit\Access_Control_$(Get-Date -Format 'yyyyMMdd').csv"
    )
    
    # This array will store all the audit results we gather
    $AuditResults = @()
    
    # Go through each folder in the list
    foreach ($FolderPath in $FolderPaths) {
        # Make sure the folder actually exists
        if (Test-Path $FolderPath) {
            Write-Host "Auditing permissions for: $FolderPath" -ForegroundColor Yellow
            
            # Recursively get all files and subfolders, including hidden/system items
            Get-ChildItem -Path $FolderPath -Recurse -Force | ForEach-Object {
                try {
                    # Get the ACL (permissions) for this file or folder
                    $Acl = Get-Acl -Path $_.FullName
                    
                    # For each access rule (who can do what), collect the info
                    foreach ($AccessRule in $Acl.Access) {
                        $AuditResults += [PSCustomObject]@{
                            Path = $_.FullName  # Full path to the item
                            Type = if ($_.PSIsContainer) { "Folder" } else { "File" }  # Is it a file or folder?
                            Identity = $AccessRule.IdentityReference  # Who has access
                            Rights = $AccessRule.FileSystemRights  # What kind of access they have
                            AccessType = $AccessRule.AccessControlType  # Allow or Deny
                            Inherited = $AccessRule.IsInherited  # Inherited from parent or not
                            LastModified = $_.LastWriteTime  # When it was last modified
                            Owner = $Acl.Owner  # Who owns the file/folder
                        }
                    }
                }
                catch {
                    # If it fails (e.g., access denied), just warn and move on
                    Write-Warning "Could not audit: $($_.FullName)"
                }
            }
        }
    }
    
    # Save all the results to a CSV file
    $AuditResults | Export-Csv -Path $OutputPath -NoTypeInformation
    
    # Create a quick summary of the audit for the terminal
    $Summary = @{
        TotalItems = $AuditResults.Count  # Total number of items we looked at
        UniqueUsers = ($AuditResults | Select-Object -ExpandProperty Identity | Sort-Object -Unique).Count  # How many unique users have permissions
        FullControlAccess = ($AuditResults | Where-Object { $_.Rights -match "FullControl" }).Count  # How many items have Full Control access
        ExternalAccess = ($AuditResults | Where-Object { $_.Identity -notmatch "DOMAIN\\" }).Count  # Entries not from your domain (possible external access)
    }
    
    # Print out the summary in the console
    Write-Host "Access Control Audit Summary:" -ForegroundColor Green
    Write-Host "Total Items Audited: $($Summary.TotalItems)" -ForegroundColor White
    Write-Host "Unique Users with Access: $($Summary.UniqueUsers)" -ForegroundColor White
    Write-Host "Full Control Permissions: $($Summary.FullControlAccess)" -ForegroundColor White
    Write-Host "External Access Entries: $($Summary.ExternalAccess)" -ForegroundColor Yellow
    Write-Host "Report saved to: $OutputPath" -ForegroundColor Green
}

