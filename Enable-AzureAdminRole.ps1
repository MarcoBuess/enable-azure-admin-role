#Requires -Modules AzureADPreview

[CmdletBinding()]
Param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$roleName,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$activationReason,
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateRange(1,8)]
    [string]$activationDuration
)

# Establish AAD session
$session = Connect-AzureAD

# AAD object id of the user of the current session
$userObjectId =
    Get-AzureADUser -Filter "UserPrincipalName eq '$($session.Account)'" |
    select -ExpandProperty ObjectId

if (-not $userObjectId) {
    throw "Your user was not found in azure active directory"
}

# Get role definition by name for requested role
$roleDefinition =
    Get-AzureADMSPrivilegedRoleDefinition -ProviderId "aadRoles" -ResourceId $session.TenantId -Filter "DisplayName eq '$roleName'"

# Check if user is eligible
$userIsEligible =
    Get-AzureADMSPrivilegedRoleAssignment -ProviderId "aadRoles" -ResourceId $session.TenantId -Filter "RoleDefinitionId eq '$($roleDefinition.Id)'" |
    ? AssignmentState -eq "Eligible" |
    % { $_.count -gt 0 }

# Check if user is eligible for the requested role
if (-not $userIsEligible) {
    throw "Your user is not eligible for the requested role"
}

# Prepare schedule
$schedule = New-Object Microsoft.Open.MSGraph.Model.AzureADMSPrivilegedSchedule
$schedule.Type = "Once"
$schedule.StartDateTime = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
$schedule.endDateTime = ((Get-Date).AddHours($activationDuration)).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")

# Send activation request
Open-AzureADMSPrivilegedRoleAssignmentRequest -ProviderId "aadRoles" `
                                              -ResourceId $session.TenantId `
                                              -RoleDefinitionID $($roleDefinition.Id) `
                                              -SubjectID $userObjectId `
                                              -Type "UserAdd" `
                                              -AssignmentState "Active" `
                                              -Schedule $schedule `
                                              -reason $activationReason `
                                              -Verbose