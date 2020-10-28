$tenant = ""

#Object to hold Site Collection information
class siteCol{
    [String]$name
    [String]$url
    [Hashtable]$lists=@{}
    [Hashtable]$contentTypes
    [String]$template
    [Boolean]$isSubSite


    siteCol([string]$name,[String]$url,[String]$template){
        <#
        -Inputs-
        [String]$name: Name of the Site Collection we are creating an object for
        [String]$url: URL suffix of the Site Collection we are creating an object for
        [String]$template: STS template to use when creating the Site Collection.
        -Outputs-
        Set $name
        Set $url
        Initialize $lists
        Initialize $contentTypes
        Set $isSubSite appropriately
        #>
        
        $this.url = $url
        $this.contentTypes = @()

        #Check if URL is for a subsite
        $this.isSubSite = (checkIfSubsiteURL -url $this.url)

    }
    <#
    -Inputs-
    -Outputs-
    #>
    [void]addSiteContentTypeToList([String]$contentTypeName,$listName) {
        If($this.lists.ContainsKey($listName)){
            $this.lists.$listName.addContentType($contentTypeName)
        }
        $this.addContentType($contentTypeName)
    }

    [void]addSiteContentTypeToSite([String]$contentTypeName) {
        If(-not $this.contentTypes.Contains($contentTypeName)){
            $this.contentTypes += $contentTypeName
        }
    }

    [void]addListToSite([String]$listName, [String]$template) {
        If(-not $this.lists.ContainsKey($listName)){
            $tempList = [list]::new("$listName")
            $this.lists.Add($listName, $tempList)
        }
        Else {
            Write-Host "List '$listName' already recorded for creation."
        }
    }
}

#Object to hold List Information
class list{
    [String]$name
    [String]$template
    [Array]$contentTypes

    list([String]$name, [String]$template){
        Write-Host "Creating list object with name '$name' and template '$template'" -ForegroundColor Yellow
        $this.name = $name
        $this.template = $template
        $this.contentTypes = @()
    }

    [void]addContentType([string]$contentTypeName){
        If(-not $this.contentTypes.Contains($contentTypeName)){
            $this.contentTypes += $contentTypeName
        }
    }
}


function checkIfSubsiteURL([String]$url){
    <#
    -Inputs-
    [String]$url: URL to check if it's for a subsite
    -Outputs-
    $True if Site URL is the same as Web URL
    $False Site URL is not the same as Web URL
    #>
    
    $web = Get-PnPWeb
    $site = Get-PnPSite

    If($web.Url -eq $site.Url) {
        Return $True
    }
    Else {
        Return $False
    }
}


function addColumnsToSiteContentType([String]$contentTypeName,$columnGroup){
    <#
    -Inputs-
    [String]$contentTypeName: Name of the Site Content Type to add columns to
    [String]$columnGroup: Name of the group containing the columns to add to the Site Content Type
    -Outputs-
    Informational for inputs given
    Progress bar
    Completion
    #>
    
    Write-Host "Adding columns from group '$columnGroup' to Site Content Type '$contentTypeName'"  -ForegroundColor Yellow
    $columns = Get-PnPField -Group $columnGroup
    $numColumns = $columns.Count
    $i = 0
    ForEach($column in $columns){
        $column = $column.InternalName
        Add-PnPFieldToContentType -Field $column -ContentType $contentTypeName
        Write-Progress -Activity "Adding column: $column" -Status "To Site Content Type: $contentTypeName. Progress:" -PercentComplete ($i/$numColumns*100)
        $i++
    }
    Write-Progress -Activity "Done adding Columns" -Completed    
}


function checkContentTypeExists([String]$contentTypeName){
    <#
    -Inputs-
    [String]$contentTypeName: Name of the Site Content Type to check for
    -Outputs-
    $True if found (object retrieved is not $null)
    $False if not found (object retrieved is $null)
    #>

    -Not((Get-PnPContentType -Identity $contentTypeName) -eq $null)
}