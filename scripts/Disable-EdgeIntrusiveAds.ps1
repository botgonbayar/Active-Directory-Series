# Disable Microsoft Edge Intrusive Ads and Scareware
# Compatible with Windows 10/11 and Intune deployment
# Author: Bat Otgonbayar
# Version: 1.0

[CmdletBinding()]
param(
    [switch]$LogToFile = $true,
    [string]$LogPath = "$env:TEMP\EdgeAdsDisable.log"
)

# Initialize logging
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry
    if ($LogToFile) {
        Add-Content -Path $LogPath -Value $logEntry
    }
}

# Check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Main script execution
try {
    Write-Log "Starting Microsoft Edge ads and scareware disable script"
    
    if (-not (Test-Administrator)) {
        Write-Log "Warning: Script not running as administrator. Some registry changes may fail." "WARN"
    }

    # Registry paths for Edge policies
    $edgePolicyPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"
    $edgeUpdatePath = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"
    $currentUserPath = "HKCU:\SOFTWARE\Policies\Microsoft\Edge"

    # Create policy registry keys if they don't exist
    $registryPaths = @($edgePolicyPath, $edgeUpdatePath, $currentUserPath)
    foreach ($path in $registryPaths) {
        if (-not (Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
            Write-Log "Created registry path: $path"
        }
    }

    # Define registry settings to disable intrusive features
    $edgeSettings = @{
        # Disable personalized ads
        "PersonalizationReportingEnabled" = 0
        
        # Disable shopping features and price comparison
        "EdgeShoppingAssistantEnabled" = 0
        "PriceComparisonEnabled" = 0
        
        # Disable edge://flags recommendations
        "ShowRecommendationsEnabled" = 0
        
        # Disable new tab page ads and content
        "NewTabPageContentEnabled" = 0
        "NewTabPageQuickLinksEnabled" = 0
        "NewTabPageAllowedBackgroundTypes" = 0
        
        # Disable search suggestions
        "SearchSuggestEnabled" = 0
        
        # Disable edge collections
        "EdgeCollectionsEnabled" = 0
        
        # Disable startup boost
        "StartupBoostEnabled" = 0
        
        # Disable background apps
        "BackgroundModeEnabled" = 0
        
        # Disable edge bar
        "EdgeBarEnabled" = 0
        
        # Disable Microsoft rewards notifications
        "ShowMicrosoftRewards" = 0
        
        # Disable follow content suggestions
        "ShowFollowButton" = 0
        
        # Disable sidebar and web widgets
        "HubsSidebarEnabled" = 0
        "WebWidgetAllowed" = 0
        
        # Disable edge workspaces
        "EdgeWorkspacesEnabled" = 0
        
        # Disable promotional tabs and notifications
        "PromotionalTabsEnabled" = 0
        "PromotionalNotificationsEnabled" = 0
        
        # Disable autofill suggestions
        "AutofillAddressEnabled" = 0
        "AutofillCreditCardEnabled" = 0
        
        # Disable password manager suggestions
        "PasswordManagerEnabled" = 0
        
        # Disable edge://settings recommendations
        "ConfigureDoNotTrack" = 1
        "TrackingPrevention" = 2
        
        # Disable edge sync
        "SyncDisabled" = 1
        
        # Disable edge telemetry
        "MetricsReportingEnabled" = 0
        "SendSiteInfoToImproveServices" = 0
        
        # Disable edge preload
        "EdgePreloadEnabled" = 0
        
        # Disable edge sleeping tabs notifications
        "SleepingTabsEnabled" = 0
        
        # Disable edge efficiency mode notifications
        "EfficiencyModeEnabled" = 0
    }

    # Apply settings to HKLM (affects all users)
    Write-Log "Applying Edge policy settings to HKLM"
    foreach ($setting in $edgeSettings.GetEnumerator()) {
        try {
            Set-ItemProperty -Path $edgePolicyPath -Name $setting.Key -Value $setting.Value -Type DWord -Force
            Write-Log "Set $($setting.Key) = $($setting.Value)"
        } catch {
            Write-Log "Failed to set $($setting.Key): $($_.Exception.Message)" "ERROR"
        }
    }

    # Apply settings to current user
    Write-Log "Applying Edge policy settings to current user"
    foreach ($setting in $edgeSettings.GetEnumerator()) {
        try {
            Set-ItemProperty -Path $currentUserPath -Name $setting.Key -Value $setting.Value -Type DWord -Force
        } catch {
            Write-Log "Failed to set current user $($setting.Key): $($_.Exception.Message)" "WARN"
        }
    }

    # Disable Edge automatic updates if running as admin
    if (Test-Administrator) {
        try {
            Set-ItemProperty -Path $edgeUpdatePath -Name "UpdateDefault" -Value 0 -Type DWord -Force
            Set-ItemProperty -Path $edgeUpdatePath -Name "Update{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}" -Value 0 -Type DWord -Force
            Write-Log "Disabled Edge automatic updates"
        } catch {
            Write-Log "Failed to disable Edge automatic updates: $($_.Exception.Message)" "WARN"
        }
    }

    # Remove Edge desktop shortcuts for scareware prevention
    $desktopPaths = @(
        "$env:PUBLIC\Desktop\Microsoft Edge.lnk",
        "$env:USERPROFILE\Desktop\Microsoft Edge.lnk"
    )
    
    foreach ($shortcut in $desktopPaths) {
        if (Test-Path $shortcut) {
            try {
                Remove-Item $shortcut -Force
                Write-Log "Removed desktop shortcut: $shortcut"
            } catch {
                Write-Log "Failed to remove shortcut $shortcut: $($_.Exception.Message)" "WARN"
            }
        }
    }

    # Disable Edge first run experience
    $firstRunPath = "HKLM:\SOFTWARE\Microsoft\Edge\FirstRunExperience"
    if (-not (Test-Path $firstRunPath)) {
        New-Item -Path $firstRunPath -Force | Out-Null
    }
    Set-ItemProperty -Path $firstRunPath -Name "FirstRunExperienceEnabled" -Value 0 -Type DWord -Force
    Write-Log "Disabled Edge first run experience"

    # Create a flag file to indicate script has run
    $flagFile = "$env:TEMP\EdgeAdsDisabled.flag"
    Set-Content -Path $flagFile -Value (Get-Date).ToString()
    Write-Log "Created completion flag file: $flagFile"

    Write-Log "Script completed successfully"
    
    # Return success code for Intune
    exit 0

} catch {
    Write-Log "Script failed with error: $($_.Exception.Message)" "ERROR"
    exit 1
}
