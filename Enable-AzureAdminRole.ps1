#Requires -Version 5.1
#Requires -Modules ActiveDirectory, AzureADPreview, @{ ModuleName="PowerShellGet"; RequiredVersion="2.2.5" }, MSAL.PS

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
    [ValidateRange(1,9)]
    [string]$activationDuration
)

# Gets upn for executing user from active directory
$userUpn =
    Get-ADUser -Filter "SamAccountName -eq '$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name.Split('\')[1])'" |
    select -ExpandProperty UserPrincipalName

# Hack to work around known issue for MFA
# Taken from http://www.anujchaudhary.com/2020/02/connect-to-azure-ad-powershell-with-mfa.html
$MsResponse =
    Get-MSALToken -Scopes @("https://graph.microsoft.com/.default") `
                  -ClientId "1b730954-1685-4b74-9bfd-dac224a7b894" `
                  -RedirectUri "https://login.microsoftonline.com/common/oauth2/nativeclient" `
                  -Authority "https://login.microsoftonline.com/common" `
                  -Interactive `
                  -ExtraQueryParameters @{claims='{"access_token" : {"amr": { "values": ["mfa"] }}}'}

# Get token for AAD Graph
$AadResponse =
    Get-MSALToken -Scopes @("https://graph.windows.net/.default") `
                  -ClientId "1b730954-1685-4b74-9bfd-dac224a7b894" `
                  -RedirectUri "https://login.microsoftonline.com/common/oauth2/nativeclient" `
                  -Authority "https://login.microsoftonline.com/common"

# Establish AAD session
$session =
    Connect-AzureAD -AadAccessToken $AadResponse.AccessToken `
                    -MsAccessToken $MsResponse.AccessToken `
                    -AccountId $userUpn

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