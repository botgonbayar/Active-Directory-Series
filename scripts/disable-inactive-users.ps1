<#
.SYNOPSIS
    Disables AD accounts that have been inactive for more than 90 days.
#>

Import-Module ActiveDirectory

$threshold = (Get-Date).AddDays(-90)

Get-ADUser -Filter * -Properties LastLogonDate |
    Where-Object { $_.Enabled -eq $true -and $_.LastLogonDate -lt $threshold } |
    ForEach-Object {
        Disable-ADAccount -Identity $_.SamAccountName
        Write-Output "Disabled inactive user: $($_.SamAccountName)"
    }
