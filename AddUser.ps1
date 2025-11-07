# Path to your CSV 

$csvPath = "C:\Temp\NewHires.csv" 

# Template user for group membership copy 

$templateUser = "challenger720" 

# Domain suffix for UPN 

$domainSuffix = "@domain.us" 

# Get template user with groups 

$templateUserObj = Get-ADUser $templateUser -Properties MemberOf 

# Import users from CSV 

$users = Import-Csv -Path $csvPath 

foreach ($user in $users) { 

# Use Initials directly from CSV 
$initials = $user.Initials 
 
# Add dot after initials in display name 
    # Determine DisplayName
    if ([string]::IsNullOrWhiteSpace($initials)) {
        $displayName = "$($user.FirstName) $($user.LastName)"
    } else {
        $displayName = "$($user.FirstName) $initials. $($user.LastName)"
    }
 
# SamAccountName and UPN from CSV Username 
$samAccountName = $user.Username 
$userPrincipalName = "$samAccountName$domainSuffix" 
 
# Convert password to secure string (make sure CSV has Password column) 
$securePassword = ConvertTo-SecureString $user.Password -AsPlainText -Force 
 
# OU from CSV 
$userOU = $user.OU 
 
Write-Host "Creating user: $displayName" 
 
# Create new AD user 
New-ADUser `
    -Name $displayName `
    -GivenName $user.FirstName `
    -Initials $initials `
    -Surname $user.LastName `
    -DisplayName $displayName `
    -SamAccountName $samAccountName `
    -UserPrincipalName $userPrincipalName `
    -Path $userOU `
    -EmployeeID $user.EmployeeID `
    -Department "XXX Department" `
    -Division "XXX Support Services Division" `
    -Title "Trainee" `
    -Manager $user.Manager `
    -Company "XXX" `
    -AccountPassword $securePassword `
    -Enabled $true `
    -ChangePasswordAtLogon $true `
    -OtherAttributes @{ 'Special-ID' = $user.'Special-ID' }

 
# Add user to groups copied from template user 
if ($templateUserObj.MemberOf.Count -gt 0) { 
    foreach ($groupDN in $templateUserObj.MemberOf) { 
        try { 
            Add-ADGroupMember -Identity $groupDN -Members $samAccountName 
        } catch { 
            Write-Warning "Failed to add $samAccountName to group ${groupDN}: $_" 
        } 
    } 
} else { 
    Write-Host "Template user $templateUser has no group memberships to copy." 
} 
 
Write-Host "---------------------------------------------`n" 
  

} 

Write-Host "User creation complete." 
