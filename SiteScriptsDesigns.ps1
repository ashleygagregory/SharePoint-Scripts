#We need to connect to the 'SharePoint Admin Site' for these actions
$Tenant = Read-Host "Please enter your 365 Tenant name, eg for 'https://contoso.sharepoint.com', just enter contoso"
Connect-PnPOnline -url "https://$($Tenant)-admin.sharepoint.com" -Interactive

$siteTemplate = Read-Host "What Site Design Template type are you making? (please enter one of the following: TeamSite, CommunicationSite, GrouplessTeamSite)"

$SiteScriptStorage = @()

$json = Read-Host "Would you like to enter a JSON SharePoint Designer value for your script? (y/n)"

If($json -eq 'n') {
    Write-Host "Skipping JSON option. Script running in script-per-list mode." -ForegroundColor Yellow
    $input = Read-Host "What is the URL of the List/Library you wish to template? (or enter 'q' to finish adding Lists/Libraries)"

    While ($input -ne 'q'){

        #Pull the List/Library from the URL and create a Script from it
        $SiteScript = Get-PnPSiteScriptFromList -Url $input

        $SiteScriptName = Read-Host "Enter a name for the Site Script, eg 'addEmailsLibrary'"

        #Upload the Site Script to M365, we can't use it yet though because no Site Design calls it
        $NewSiteScript = Add-PnPSiteScript -Title $SiteScriptName -Content $SiteScript

        $SiteScriptStorage = $SiteScriptStorage + $($NewSiteScript.Id)
        Write-Host "Created Site Script $SiteScriptName and stored with ID $($NewSiteScript.Id)"
        $input = Read-Host "What is the URL of the List/Library you wish to template? (or enter 'q' to finish adding Lists/Libraries)"
    }
}
Else {
    Write-Host "Continuing with JSON option. Script running in script-per-JSON mode." -ForegroundColor Yellow
    $SiteScript = Read-Host "Enter your JSON data:"
    $SiteScriptName = Read-Host "Enter a name for the Site Script, eg 'addEmailsLibrary'"
    #Upload the Site Script to M365, we can't use it yet though because no Site Design calls it
    $NewSiteScript = Add-PnPSiteScript -Title $SiteScriptName -Content $SiteScript

    $SiteScriptStorage = $SiteScriptStorage + $($NewSiteScript.Id)
}

$SiteDesignName = Read-Host "Enter a name for the Site Design, eg 'Team Site + Emails Library"
$SiteDesignDesc = Read-Host "Enter a description for this Site Design, eg 'Adds an Emails Library to a Team Site with required columns and views'"

#Create the Site Design and tell it to use the Site Script(s) noted, in this example you are only using the one pulled above though.
Add-PnPSiteDesign -Title $SiteDesignName -SiteScriptIds $SiteScriptStorage -Description $SiteDesignDesc -WebTemplate $siteTemplate