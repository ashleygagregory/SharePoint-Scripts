$site = 'https://contoso.sharepoint.com/sites/cases'
$list = 'Documents'
$firstLevelFolder = 'Birdman, Harvey T65432'

#We are using PnP here just to make it easier to get the Context,List, and Folder Content Type ID without dealing with potential auth issues that would detract from the actual issue at hand
Connect-PnPOnline -Url $site -Interactive
$ctx = New-Object Microsoft.SharePoint.Client.ClientContext($site)
$ctx = Get-PnPContext -Verbose 
$documents = Get-PnPList -Identity $list
$folderContentTypeID = (Get-PnPContentType -List $list -Identity 'Folder').Id.StringValue


#From here on is pure CSOM
    $name = "Folder created at $(Get-Date)"
    $info = [Microsoft.SharePoint.Client.ListItemCreationInformation]::new()
    $info.UnderlyingObjectType = [Microsoft.SharePoint.Client.FileSystemObjectType]::Folder
    $info.LeafName = $name.Trim()
    $info.FolderUrl = "$site\$list"

    [Microsoft.SharePoint.Client.ListItem]$newItem = $documents.AddItem($info)
    $newItem["ContentTypeId"] = $folderContentTypeID
    $newItem["Title"] = $name

    $newItem.Update()

    $ctx.ExecuteQuery()
    <#
    #This is how you can call SP to make a Folder but you cannot specify Content Type
    $name = $name + 'but not specifying content type'
    $newFolder = $documents.RootFolder.Folders
    $ctx.Load($newFolder)
    $ctx.ExecuteQuery()
    #>
#Disconnecting to clean up
Disconnect-PnPOnline
