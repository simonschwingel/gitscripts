# gitscripts
a collection of diverse scripts

script-name | description | synopsis
--- | --- | ---
`export-subscriptions.ps1` | iterates through all Azure subscriptions of a logged in user and collects tenant-id, subscription-id, subscription-name and account owner of the subscription | provide parameter `$file` to adjust output path. 
`Get-RoleAssignemnts.ps1` | iterates through all RBAC assignments within the specified subscription and collects DisplayName, SignIn, RoleDefinition, Type, Scope of each assigned role. Collected data will be saved into RBACList.csv if not specified otherwise. You need to be logged in to Azure (`Login-AzureRMAccount`) | provide mandatory parameter `$subscriptionId` 
