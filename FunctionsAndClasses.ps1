#Object to hold Site Collection information
class siteCol{
    [String]$name
    [String]$url
    [Hashtable]$lists=@{}
    [Array]$contentTypes
    [Boolean]$isSubSite


    siteCol([string]$name,$url){
        <#
        -Inputs-
        [String]$name: Name of the Site Collection we are creating an object for
        [String]$url: URL of the Site Collection we are creating an object for
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
    [void]addSiteContentTypeToList([String]$contentTypeName,$listName){
        #Check we aren't working without a Document Library name, otherwise assume that we just want to add a Site Content Type
        If(($listName -ne $null) -and ($listName -ne "")){
            If(-not $this.lists.ContainsKey($listName)){
                $tempList = [list]::new("$listName")
                $this.lists.Add($listName, $tempList)
            }
            
            $this.lists.$listName.addContentType($contentTypeName)
        }
        
        $this.addContentType($contentTypeName)
    }

    [void]addContentType([String]$contentTypeName){
        If(-not $this.contentTypes.Contains($contentTypeName)){
            $this.contentTypes += $contentTypeName
        }
    }
}

#Object to hold List Information
class list{
    [String]$name
    [Array]$contentTypes

    list([String]$name){
        Write-Host "Creating list object with name $name" -ForegroundColor Yellow
        $this.name = $name
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
    $True if 5x '/' and character(s) found beyond it (assumption for subsite)
    $False if 4x '/' OR 5x '/' and no character(s) found beyond it (assumption for a site collection)
    #>
    
    $countFwdSlashes = ($url.ToCharArray() | Where-Object {$_ -eq '/'} | Measure-Object).Count

    If($countFwdSlashes -gt 4){
        $indexLastFwdSlash = $url.LastIndexOf('/')
        $indexLastFwdSlash++
        #Check the character after the 5th '/', if there's a character we assume this is a subsite URL
        If($url[$indexLastFwdSlash].Length -eq 1){
            $true
        }
        Else{
            $false
        }
    }
    Else{
        $false
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