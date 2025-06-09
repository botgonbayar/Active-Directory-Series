<#
.SYNOPSIS
    Bulk creates AD users from a CSV file.
.DESCRIPTION
    This script creates new users in a specified OU based on the input CSV file.
    Each user will be assigned a temporary password and must change it at next logon.
.NOTES
    Author: Bat Otgonbayar
    Requires: Active Directory 
#>

Import-Module ActiveDirectory

$OU = "OU=Secora Users,DC=secora,DC=lab"
$CSVPath = ".\users.csv"

if (!(Test-Path $CSVPath)) {
    Write-Error "CSV file not found at $CSVPath"
    exit
}

$users = Import-Csv $CSVPath

foreach ($user in $users) {
    $SecurePassword = ConvertTo-SecureString $user.Password -AsPlainText -Force
    New-ADUser `
        -Name $user.Name `
        -SamAccountName $user.Username `
        -UserPrincipalName "$($user.Username)@secora.lab" `
        -GivenName $user.FirstName `
        -Surname $user.LastName `
        -DisplayName $user.Name `
        -EmailAddress $user.Email `
        -Path $OU `
        -AccountPassword $SecurePassword `
        -Enabled $true `
        -ChangePasswordAtLogon $true
}
