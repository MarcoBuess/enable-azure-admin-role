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

## Resources

* http://www.anujchaudhary.com/2020/02/connect-to-azure-ad-powershell-with-mfa.html
* https://docs.microsoft.com/en-us/azure/active-directory/privileged-identity-management/powershell-for-azure-ad-roles