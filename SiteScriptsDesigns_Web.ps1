#We need to connect to the 'SharePoint Admin Site' for these actions
$Tenant = Read-Host "Please enter your 365 Tenant name, eg for 'https://contoso.sharepoint.com', just enter contoso"
Connect-PnPOnline -url "https://$($Tenant)-admin.sharepoint.com" -Interactive

$siteTemplate = Read-Host "What Site Design Template type are you making? (please enter one of the following: TeamSite, CommunicationSite, GrouplessTeamSite)"

$SiteScriptStorage = @()

$json = Read-Host "Would you like to enter a JSON SharePoint Designer value for your script? (y/n)"

If($json -eq 'n') {
    Write-Host "Skipping JSON option. Script running in script-per-list mode." -ForegroundColor Yellow
    $input = Read-Host "What is the URL of the Site you wish to template?"
    $lists = Read-Host "What are the lists/Libraries you wish to include? Enter these separated by semicolon's and include 'lists/' before any lists, and no unnecessary spaces, eg 'lists/Central Register;Shared Documents;Emails'`nNote that this will also include the Columns and Views from these locations."
    [String[]]$listsArray = $lists.Split(";")

    #Pull the List/Library from the URL and create a Script from it
    $SiteScript = Get-PnPSiteScriptFromWeb -Url $input -IncludeAll -Lists $listsArray

    $SiteScriptName = Read-Host "Enter a name for the Site Script, eg 'ProjectSite_Script'"

    #Upload the Site Script to M365, we can't use it yet though because no Site Design calls it
    $NewSiteScript = Add-PnPSiteScript -Title $SiteScriptName -Content $SiteScript

    $SiteScriptStorage = $SiteScriptStorage + $($NewSiteScript.Id)
    Write-Host "Created Site Script $SiteScriptName and stored with ID $($NewSiteScript.Id)"
    
}
Else {
    Write-Host "Continuing with JSON option. Script running in script-per-JSON mode." -ForegroundColor Yellow
    $SiteScript = Read-Host "Enter your JSON data:"
    $SiteScriptName = Read-Host "Enter a name for the Site Script, eg 'ProjectSite_Script'"
    #Upload the Site Script to M365, we can't use it yet though because no Site Design calls it
    $NewSiteScript = Add-PnPSiteScript -Title $SiteScriptName -Content $SiteScript

    $SiteScriptStorage = $SiteScriptStorage + $($NewSiteScript.Id)
}

$SiteDesignName = Read-Host "Enter a name for the Site Design, eg 'ProjectSite"
$SiteDesignDesc = Read-Host "Enter a description for this Site Design, eg 'Project Site with an Emails Library'"

#Create the Site Design and tell it to use the Site Script(s) noted, in this example you are only using the one pulled above though.
Add-PnPSiteDesign -Title $SiteDesignName -SiteScriptIds $SiteScriptStorage -Description $SiteDesignDesc -WebTemplate $siteTemplate

Disconnect-PnPOnline