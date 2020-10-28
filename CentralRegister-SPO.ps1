$SPOTenant = Read-Host "Enter your SharePoint Tenant name"
$SPOAdmin = "https://" + $SPOTenant + "-admin.sharepoint.com"
Connect-SPOService -url $SPOAdmin

$sites = Get-SPOSite
#Connect-PnPOnline -url -SPOManagementShell