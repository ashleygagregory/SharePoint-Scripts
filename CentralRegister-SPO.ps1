$userInput = Read-Host -Prompt "Please enter the List URL for the Central Register"
$userInput -match "(((https:\/\/)(.+)(\.sharepoint\.com).+)((\/Lists\/).+\/?))(?:\/AllItems\.aspx)?" | Out-Null

$tenant = $Matches[4]
$centralRegister = $Matches[1] -replace '/AllItems.aspx',''
$centralRegisterRelative = $Matches[6] -replace '/AllItems.aspx',''
$site = $Matches[2]

Connect-PnPOnline -Url "https://$tenant-admin.sharepoint.com" -Interactive

$tenantSites = Get-PnPTenantSite -Detailed

Connect-PnPOnline -Url $site -Interactive

Try {
    Get-PnPField -List $centralRegisterRelative -Identity "Site Collection URL"
}
Catch {
    Add-PnPField -List $centralRegisterRelative -InternalName 'siteCollectionUrl' -DisplayName 'Site Collection URL' -Type URL -AddToDefaultView -Group "Custom Columns"
}

Try {
    Get-PnPField -List $centralRegisterRelative -Identity "Site Collection URL Unique"
}
Catch {
    Add-PnPField -List $centralRegisterRelative -InternalName 'siteCollectionUrlUnique' -DisplayName 'Site Collection URL Unique' -Type Text -Group "Custom Columns"
    Set-PnPField -List $centralRegisterRelative -Identity 'siteCollectionUrlUnique' -Values @{"EnforceUniqueValues" = $True}
}

Try {
    Get-PnPField -List $centralRegisterRelative -Identity "Site Collection Owner"
}
Catch {
    Add-PnPField -List $centralRegisterRelative -InternalName 'siteCollectionOwner' -DisplayName 'Site Collection Owner' -Type User -AddToDefaultView -Group "Custom Columns"
}

Try {
    Get-PnPField -List $centralRegisterRelative -Identity "Site Collection Created"
}
Catch {
    Add-PnPField -List $centralRegisterRelative -InternalName 'siteCollectionCreated' -DisplayName 'Site Collection Created' -Type DateTime -AddToDefaultView -Group "Custom Columns"
}

$batch = New-PnPBatch

ForEach($siteCol in $tenantSites) {
    If([string]::IsNullOrEmpty($siteCol.Title)){
        $siteCol.Title = $siteCol.Url
    }
    If([string]::IsNullOrEmpty($siteCol.Owner)){
        If([System.Guid]::Empty -match $siteCol.GroupId){
            Write-Host "Empty Owner and empty GUID, assigning Site for All Authenticated Users"
            $owner = "c:0-.f|rolemanager|spo-grid-all-users/$(Get-PnPTenantID)"
        }
        Else{
            $owner = "c:0o.c|federateddirectoryclaimprovider|$($siteCol.GroupId)"
        }
        
    }
    Else{
        $owner = $siteCol.Owner
    }
    Write-Host "`n$($siteCol.Title)`n$owner`n$($siteCol.Url)"
    If($siteCol.Url -match "(https:\/\/.+-my\.sharepoint\.com).*"){
        Write-Host "OneDrive site identified, skipping"
    }
    Else{
            Add-PnPListItem -List $centralRegisterRelative -Batch $batch -Values @{"Title" = $siteCol.Title; "siteCollectionUrl" = $siteCol.Url; "siteCollectionUrlUnique" = $siteCol.Url; "siteCollectionOwner" = $owner}
    }
    $count--
}

Invoke-PnPBatch -Batch $batch