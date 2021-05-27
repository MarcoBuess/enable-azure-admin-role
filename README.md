# Enable-AzureAdminRole

The skript enables the role specified by `roleName` for a duration given by `activationDuration` and a reason given by `activationReason`.

## Syntax

```powershell
.\Enable-AzureAdminRole.ps1 -roleName [string] -activationReason [string] -activationDuration [int (1-8 Hours)]
```

## Example

```powershell
.\Enable-AzureAdminRole.ps1 -roleName "Intune Administrator" -activationReason "Daily" -activationDuration 8
```

## Known Issues

There is a problem with the requirement for MFA when connecting from an internal network.
```powershell
Open-AzureADMSPrivilegedRoleAssignmentRequest : Error occurred while executing OpenAzureADMSPrivilegedRoleAssignmentRequest
Code: RoleAssignmentRequestPolicyValidationFailed
Message: The following policy rules failed: ["MfaRule"]
InnerError:
  RequestId: ee802046-fc77-4774-ab07-44c142dfe9f6
  DateTimeStamp: Thu, 27 May 2021 11:59:10 GMT
HttpStatusCode: BadRequest
HttpStatusDescription: Bad Request
HttpResponseStatus: Completed
```
