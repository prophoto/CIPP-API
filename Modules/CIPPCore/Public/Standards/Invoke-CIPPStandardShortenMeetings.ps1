function Invoke-CIPPStandardShortenMeetings {
    <#
    .FUNCTIONALITY
        Internal
    .COMPONENT
        (APIName) ShortenMeetings
    .SYNOPSIS
        (Label) Set shorten meetings state
    .DESCRIPTION
        (Helptext) Sets the shorten meetings settings on a tenant level. This will shorten meetings by the selected amount of minutes. Valid values are 0 to 29. Short meetings are under 60 minutes, long meetings are over 60 minutes.
        (DocsDescription) Sets the shorten meetings settings on a tenant level. This will shorten meetings by the selected amount of minutes. Valid values are 0 to 29. Short meetings are under 60 minutes, long meetings are over 60 minutes.
    .NOTES
        CAT
            Exchange Standards
        TAG
        ADDEDCOMPONENT
            {"type":"autoComplete","multiple":false,"label":"Select value","name":"standards.ShortenMeetings.ShortenEventScopeDefault","options":[{"label":"Disabled/None","value":"None"},{"label":"End early","value":"EndEarly"},{"label":"Start late","value":"StartLate"}]}
            {"type":"number","name":"standards.ShortenMeetings.DefaultMinutesToReduceShortEventsBy","label":"Minutes to reduce short calendar events by (Default is 5)","defaultValue":5}
            {"type":"number","name":"standards.ShortenMeetings.DefaultMinutesToReduceLongEventsBy","label":"Minutes to reduce long calendar events by (Default is 10)","defaultValue":10}
        IMPACT
            Medium Impact
        ADDEDDATE
            2024-05-27
        POWERSHELLEQUIVALENT
            Set-OrganizationConfig -ShortenEventScopeDefault -DefaultMinutesToReduceShortEventsBy -DefaultMinutesToReduceLongEventsBy
        RECOMMENDEDBY
        UPDATECOMMENTBLOCK
            Run the Tools\Update-StandardsComments.ps1 script to update this comment block
    .LINK
        https://docs.cipp.app/user-documentation/tenant/standards/list-standards/exchange-standards#medium-impact
    #>

    param($Tenant, $Settings)
    ##$Rerun -Type Standard -Tenant $Tenant -Settings $Settings 'ShortenMeetings'

    # Input validation
    if ([Int32]$Settings.DefaultMinutesToReduceShortEventsBy -lt 0 -or [Int32]$Settings.DefaultMinutesToReduceShortEventsBy -gt 29) {
        Write-LogMessage -API 'Standards' -tenant $Tenant -message 'ShortenMeetings: Invalid setting specified. DefaultMinutesToReduceShortEventsBy must be an integer between 0 and 29' -sev Error
        Return
    }
    if ([Int32]$Settings.DefaultMinutesToReduceLongEventsBy -lt 0 -or [Int32]$Settings.DefaultMinutesToReduceLongEventsBy -gt 29) {
        Write-LogMessage -API 'Standards' -tenant $Tenant -message 'ShortenMeetings: Invalid setting specified. DefaultMinutesToReduceLongEventsBy must be an integer between 0 and 29' -sev Error
        Return
    }

    # Get state value using null-coalescing operator
    $scopeDefault = $Settings.ShortenEventScopeDefault.value ?? $Settings.ShortenEventScopeDefault

    $CurrentState = New-ExoRequest -tenantid $Tenant -cmdlet 'Get-OrganizationConfig' |
        Select-Object -Property ShortenEventScopeDefault, DefaultMinutesToReduceShortEventsBy, DefaultMinutesToReduceLongEventsBy
    $CorrectState = if ($CurrentState.ShortenEventScopeDefault -eq $scopeDefault -and
        $CurrentState.DefaultMinutesToReduceShortEventsBy -eq $Settings.DefaultMinutesToReduceShortEventsBy -and
        $CurrentState.DefaultMinutesToReduceLongEventsBy -eq $Settings.DefaultMinutesToReduceLongEventsBy) { $true } else { $false }

    if ($Settings.remediate -eq $true) {
        Write-Host 'Time to remediate'

        if ($CorrectState -eq $true) {
            Write-LogMessage -API 'Standards' -tenant $Tenant -message 'Shorten meetings settings are already in the correct state. ' -sev Info
        } else {
            try {
                $null = New-ExoRequest -tenantid $Tenant -cmdlet 'Set-OrganizationConfig' -cmdParams @{ShortenEventScopeDefault = $Settings.ShortenEventScopeDefault; DefaultMinutesToReduceShortEventsBy = $Settings.DefaultMinutesToReduceShortEventsBy; DefaultMinutesToReduceLongEventsBy = $Settings.DefaultMinutesToReduceLongEventsBy }
                Write-LogMessage -API 'Standards' -tenant $Tenant -message "Shorten meetings settings have been set to the following state. State: $($Settings.ShortenEventScopeDefault), Short:$($Settings.DefaultMinutesToReduceShortEventsBy), Long: $($Settings.DefaultMinutesToReduceLongEventsBy)" -sev Info
            } catch {
                $ErrorMessage = Get-CippException -Exception $_
                Write-LogMessage -API 'Standards' -tenant $Tenant -message "Failed to set shorten meetings settings. Error: $($ErrorMessage.NormalizedError)" -sev Error -LogData $ErrorMessage
            }
        }
    }

    if ($Settings.alert -eq $true) {

        if ($CorrectState -eq $true) {
            Write-LogMessage -API 'Standards' -tenant $Tenant -message "Shorten meetings settings are already in the correct state. Current state: $($CurrentState.ShortenEventScopeDefault), Short:$($CurrentState.DefaultMinutesToReduceShortEventsBy), Long: $($CurrentState.DefaultMinutesToReduceLongEventsBy)" -sev Info
        } else {
            Write-LogMessage -API 'Standards' -tenant $Tenant -message "Shorten meetings settings are not in the correct state. Current state: $($CurrentState.ShortenEventScopeDefault), Short:$($CurrentState.DefaultMinutesToReduceShortEventsBy), Long: $($CurrentState.DefaultMinutesToReduceLongEventsBy)" -sev Alert
        }
    }

    if ($Settings.report -eq $true) {

        if ($CorrectState -eq $true) {
            Add-CIPPBPAField -FieldName 'ShortenMeetings' -FieldValue $CorrectState -StoreAs bool -Tenant $Tenant
        } else {
            Add-CIPPBPAField -FieldName 'ShortenMeetings' -FieldValue $CurrentState -StoreAs json -Tenant $Tenant
        }
    }
}
