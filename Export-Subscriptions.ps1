param(
    [string]$file=((Get-Location).Path + '\subscription-tenant-list.csv')
)

# Login Function (needed only locally)
Function Login
{
    $needLogin = $true

    # checking the AzureRM connection if login is needed
    Try 
    {
        $content = Get-AzureRmContext
        if ($content) 
        {
            $needLogin = ([string]::IsNullOrEmpty($content.Account))
        } 
    } 
    Catch 
    {
        if ($_ -like "*Login-AzureRmAccount to login*") 
        {   
            $needLogin = $true
        } 
        else 
        {
            Write-Host "You are already logged in to Azure, that's good."
            throw
        }
    }

    if ($needLogin)
    {
        Write-Host "You need to login to Azure"
        Login-AzureRmAccount
    }
}

#checking if you are on Azure Shell
if ( (Get-Module | where-Object {$_.Name -like "AzureAD.Standard.Preview"}).Count ) {
    Write-Host "You are on Azure Shell"
}
else {
    Write-Host "You are working locally"
    
    # check for and install the AzureRM if needed
    Import-Module AzureRm.Resources -ErrorAction SilentlyContinue | Out-Null 
    If ( !(Get-Module | where-Object {$_.Name -like "AzureRM.Resources"}).Count ) { Install-Module AzureRM -scope CurrentUser}

    # Loggin in to Azure (if needed)
    Login
}

$subs = Get-AzureRmSubscription 
$items = @()

foreach ($sub in $subs)
{
    Set-AzureRmContext -SubscriptionObject $sub
    $account = Get-AzureRmRoleAssignment -IncludeClassicAdministrators | Where-Object RoleDefinitionName -eq 'ServiceAdministrator;AccountAdministrator'
    $item = New-Object -TypeName psobject 
    $item | Add-Member -MemberType NoteProperty -Name TenantId -Value $sub.TenantId
    $item | Add-Member -MemberType NoteProperty -Name SubscriptionId -Value $sub.Id
    $item | Add-Member -MemberType NoteProperty -Name SubscriptionName -Value $sub.Name   
    $item | Add-Member -MemberType NoteProperty -Name Account -Value $account.SignInName
    $items += ,$item
}

Write-Host "Finished processing - exporting the following results to csv-file:"

$items
$items | Export-Csv -Path $file -Force 