param(
    [Parameter(Mandatory=$true)][string]$subscriptionId,
    [string]$file=((Get-Location).Path + '\RBACList.csv')
)

$d = Select-AzureRmSubscription -SubscriptionId $subscriptionId
$d = New-Item -Path $file -Value 'DisplayName,SignIn,RoleDefinition,Type,Scope' -ItemType File -Force
Add-Content -Path $file ''
[int]$counter = 0

function DisplayRoleAssignemnts 
{
    param(
        $ra
    )

    $line = $roleAssignment.DisplayName +','+ $roleAssignment.SignInName + ',' + $roleAssignment.RoleDefinitionName + ',' + $roleAssignment.ObjectType + ',' + $roleAssignment.Scope
    Write-Host $line 
    Add-Content -Path $file $line
    Set-Variable -Name counter -Value ($counter+1) -Scope 1
}

Write-Host Subscription $subscriptionId -ForegroundColor Green
foreach ($roleAssignment in Get-AzureRmRoleAssignment -IncludeClassicAdministrators)
{
    if ($roleAssignment.Scope -eq ('/subscriptions/' + $subscriptionId))
    {
        DisplayRoleAssignemnts $roleAssignment 
    }
}

foreach ($rg in Get-AzureRmResourceGroup)
{
    Write-Host $rg.ResourceGroupName -ForegroundColor Green
    foreach ($roleAssignment in Get-AzureRmRoleAssignment -ResourceGroupName $rg.ResourceGroupName)
    {
        DisplayRoleAssignemnts $roleAssignment 
    }
}
Write-Host Found $counter RoleAssignments -ForegroundColor Yellow 
