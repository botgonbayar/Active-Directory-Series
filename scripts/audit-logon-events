<#
.SYNOPSIS
    Queries logon and logoff events from the Security event log.
.DESCRIPTION
    Looks for Event ID 4624 (logon) and 4634 (logoff).
#>

$Events = Get-WinEvent -FilterHashtable @{
    LogName='Security';
    ID=@(4624,4634);
    StartTime=(Get-Date).AddDays(-7)
} | Select-Object TimeCreated, Id, Message

$Events | Export-Csv .\logon-events.csv -NoTypeInformation

Write-Output "Exported recent logon/logoff events to logon-events.csv"
