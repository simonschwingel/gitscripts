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

    # check for and install the AzureAD if needed
    Import-Module AzureAD -ErrorAction SilentlyContinue |Out-Null
    if ( !(Get-Module | where-Object {$_.Name -like "AzureAD"}).Count ) { Install-Module AzureAD -scope CurrentUser }

    # Loggin in to Azure (if needed)
    Login
}

$subs = Get-AzureRmSubscription 
$items = @()

foreach ($sub in $subs)
{
    Set-AzureRmContext -SubscriptionObject $sub
    if ($null -eq $tenant -or $tenant.ObjectId -ne $sub.TenantId) {
        Connect-AzureAD -TenantId $sub.TenantId
        $tenant = Get-AzureADTenantDetail
    }
    $account = Get-AzureRmRoleAssignment -IncludeClassicAdministrators | Where-Object RoleDefinitionName -eq 'ServiceAdministrator;AccountAdministrator'
    try {
        $user = Get-AzureADUser -ObjectId $account.SignInName
    } catch {
        $user = New-Object -TypeName psobject 
        $tmp = $_.Exception.Message -replace "`n|`r"," -- "
        $user | Add-Member -MemberType NoteProperty -Name UserType -Value $tmp
    }

    $item = New-Object -TypeName psobject 
    $item | Add-Member -MemberType NoteProperty -Name TenantId -Value $sub.TenantId
    $item | Add-Member -MemberType NoteProperty -Name TenantURL -Value $($tenant.VerifiedDomains | Where-Object Initial -eq $true).Name
    $item | Add-Member -MemberType NoteProperty -Name SubscriptionId -Value $sub.Id
    $item | Add-Member -MemberType NoteProperty -Name SubscriptionName -Value $sub.Name   
    $item | Add-Member -MemberType NoteProperty -Name Account -Value $account.SignInName
    $item | Add-Member -MemberType NoteProperty -Name UserType -Value $user.UserType
    $item | Add-Member -MemberType NoteProperty -Name TenantVerifiedDomains -Value $($($tenant.VerifiedDomains | Select-Object -ExpandProperty Name) -join ";")
    
    $items += ,$item
}

Write-Host "Finished processing - exporting the following results to csv-file:"

$items
$items | Export-Csv -Path $file -Force 