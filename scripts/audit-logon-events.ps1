.DESCRIPTION
    This script looks for Event ID 4624 (logon) and 4634 (logoff) from the Security log over the past 7 days. 
    It extracts useful details like time, event ID, and message content — and then exports everything to a CSV file.

    Great for investigating user activity, login trends, or detecting suspicious behavior.

.EXAMPLE
    # Run the script to collect logon/logoff data from the past 7 days
    .\Get-LogonEvents.ps1

.NOTES
    - You’ll need to run this as an administrator to access the Security event log.
    - Use Excel or Power BI to analyze the CSV further.
    - For more targeted filtering (specific users, computers, etc.), add additional conditions to the filter hashtable.

# Query the Security log for successful logon (4624) and logoff (4634) events from the past 7 days
$Events = Get-WinEvent -FilterHashtable @{
    LogName = 'Security'
    ID = @(4624, 4634)
    StartTime = (Get-Date).AddDays(-7)  # Only go back 7 days
} | Select-Object TimeCreated, Id, Message  # Only grab the useful fields for reporting

# Export the results to a CSV file in the current directory
$Events | Export-Csv .\logon-events.csv -NoTypeInformation

# Let the user know it’s done
Write-Output "Exported recent logon/logoff events to logon-events.csv"
