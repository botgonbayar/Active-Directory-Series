.DESCRIPTION
    This function searches the Windows Security log for specific Event IDs (default is 4624 for logon and 4634 for logoff),
    starting from a specified number of days ago. It captures basic details like the timestamp, event ID, and message content,
    then saves the results to a CSV file for further analysis.

.NOTES
    - Must be run with administrator privileges to access the Security event log.
    - Useful for investigations, compliance reports, or login activity reviews.
#>

function Get-LogonEvents {
    param(
        [int]$DaysBack = 7,  # How far back to go in the event log
        [int[]]$EventIDs = @(4624, 4634),  # Default to logon and logoff events
        [string]$OutputPath = ".\logon-events_$(Get-Date -Format 'yyyyMMdd').csv"  # Default filename
    )

    # Let the user know what’s happening
    Write-Host "Querying Security event log for Event IDs $($EventIDs -join ', ') from the last $DaysBack days..." -ForegroundColor Cyan

    try {
        # Build the filter to get the events
        $Events = Get-WinEvent -FilterHashtable @{
            LogName = 'Security'
            ID = $EventIDs
            StartTime = (Get-Date).AddDays(-$DaysBack)
        } | Select-Object TimeCreated, Id, Message

        # Export the results to CSV
        $Events | Export-Csv -Path $OutputPath -NoTypeInformation

        Write-Host "Success! Exported $($Events.Count) events to $OutputPath" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to retrieve or export events. Error: $_"
    }
}
