<#
.SYNOPSIS
Downloads Current Microsoft Updates

.DESCRIPTION
Downloads Current Microsoft Updates
Requires BITS for downloading the updates
Requires Internet access for downloading the updates

.LINK
https://www.osdeploy.com/osdupdate/functions/get-downosdupdate

.PARAMETER DownloadPath
Directory of the Downloads

.PARAMETER InputObject
Paired with Get-OSDUpdate
Get-OSDUpdate | Get-DownOSDUpdate

.PARAMETER Catalog
Get-OSDUpdate.Catalog Property

.PARAMETER UpdateArch
Architecture of the Update
Get-OSDUpdate.UpdateArch Property

.PARAMETER UpdateBuild
Windows Build for the Update
Get-OSDUpdate.UpdateBuild Property

.PARAMETER OfficeProfile
Microsoft Office Update Type

.PARAMETER GridView
Displays the results in GridView with -PassThru
#>

function Get-DownOSDUpdate {
    [CmdletBinding()]
    PARAM (
        [Parameter(Mandatory = $True)]
        [string]$DownloadPath,

        [Parameter(ValueFromPipeline = $true)]
        [Object[]]$InputObject,

        [ValidateSet(
            'Office 2010 32-Bit',
            'Office 2010 64-Bit',
            'Office 2013 32-Bit',
            'Office 2013 64-Bit',
            'Office 2016 32-Bit',
            'Office 2016 64-Bit',
            'Windows 7',
            'Windows 10',
            'Windows Server 2012 R2',
            'Windows Server 2016',
            'Windows Server 2019')]
        [Alias('CatalogOffice','CatalogWindows')]
        [string]$Catalog,

        [ValidateSet ('x64','x86')]
        [string]$UpdateArch,

        [ValidateSet (1903,1809,1803,1709,1703,1607,1511,1507)]
        [string]$UpdateBuild,

        [switch]$GridView
    )

    BEGIN {
        #===================================================================================================
        #   DownloadPath
        #===================================================================================================
        if (!(Test-Path "$DownloadPath")) {New-Item -Path "$DownloadPath" -ItemType Directory -Force | Out-Null}
        #===================================================================================================
    }

    PROCESS {
        #===================================================================================================
        #   Get-OSDUpdate
        #===================================================================================================
        $OSDUpdate = @()
        if ($InputObject) {
            $OSDUpdate = $InputObject
        } else {
            $OSDUpdate = Get-OSDUpdate
        }
        #===================================================================================================
        #   Filter Catalog
        #===================================================================================================
        if ($Catalog) {
            $OSDUpdate = $OSDUpdate | Where-Object {$_.Catalog -eq $Catalog}
        }
        #===================================================================================================
        #   UpdateArch
        #===================================================================================================
        if ($UpdateArch -eq 'x64') {$OSDUpdate = $OSDUpdate | Where-Object {$_.UpdateArch -eq 'x64'}}
        if ($UpdateArch -eq 'x86') {$OSDUpdate = $OSDUpdate | Where-Object {$_.UpdateArch -eq 'x86'}}
        #===================================================================================================
        #   UpdateBuild
        #===================================================================================================
        if ($UpdateBuild -eq '1507') {$OSDUpdate = $OSDUpdate | Where-Object {$_.UpdateBuild -eq '1507'}}
        if ($UpdateBuild -eq '1511') {$OSDUpdate = $OSDUpdate | Where-Object {$_.UpdateBuild -eq '1511'}}
        if ($UpdateBuild -eq '1607') {$OSDUpdate = $OSDUpdate | Where-Object {$_.UpdateBuild -eq '1607'}}
        if ($UpdateBuild -eq '1703') {$OSDUpdate = $OSDUpdate | Where-Object {$_.UpdateBuild -eq '1703'}}
        if ($UpdateBuild -eq '1709') {$OSDUpdate = $OSDUpdate | Where-Object {$_.UpdateBuild -eq '1709'}}
        if ($UpdateBuild -eq '1803') {$OSDUpdate = $OSDUpdate | Where-Object {$_.UpdateBuild -eq '1803'}}
        if ($UpdateBuild -eq '1809') {$OSDUpdate = $OSDUpdate | Where-Object {$_.UpdateBuild -eq '1809'}}
        if ($UpdateBuild -eq '1903') {$OSDUpdate = $OSDUpdate | Where-Object {$_.UpdateBuild -eq '1903'}}
        #===================================================================================================
        #   GridView
        #===================================================================================================
        $OSDUpdate = $OSDUpdate | Sort-Object DateCreated -Descending
        if ($GridView.IsPresent) {$OSDUpdate = $OSDUpdate | Out-GridView -PassThru -Title "Select OSDUpdate Downloads"}
        #===================================================================================================
        #   Download
        #===================================================================================================
        foreach ($Update in $OSDUpdate) {
            $UpdateFile = $($Update.FileName)
            $MspFile = $UpdateFile -replace '.cab', '.msp'
            $DownloadDirectory = "$DownloadPath\$($Update.Title)"
            if (!(Test-Path "$DownloadDirectory")) {New-Item -Path "$DownloadDirectory" -ItemType Directory -Force | Out-Null}

            if ($Update.Catalog -like "*Office*") {
                Write-Host "$DownloadDirectory\$MspFile" -ForegroundColor Cyan
            
                if (!(Test-Path "$DownloadDirectory\$MspFile")) {
                    Write-Host "Download: $($Update.OriginUri)" -ForegroundColor Gray
                    Start-BitsTransfer -Source $($Update.OriginUri) -Destination "$DownloadDirectory\$UpdateFile"
                }
        
                if ((Test-Path "$DownloadDirectory\$UpdateFile") -and (!(Test-Path "$DownloadDirectory\$MspFile"))) {
                    Write-Host "Expand: $DownloadDirectory\$MspFile" -ForegroundColor Gray
                    expand "$DownloadDirectory\$UpdateFile" -F:* "$DownloadDirectory" | Out-Null
                }
        
                if ((Test-Path "$DownloadDirectory\$UpdateFile") -and (Test-Path "$DownloadDirectory\$MspFile")) {
                    Write-Host "Remove: $DownloadDirectory\$UpdateFile" -ForegroundColor Gray
                    Remove-Item "$DownloadDirectory\$UpdateFile" -Force | Out-Null
                }
            }

            if ($Update.Catalog -like "*Windows*") {
                Write-Host "$($Update.Title)" -ForegroundColor Cyan
                Write-Host "$DownloadDirectory\$UpdateFile" -ForegroundColor Gray

                if (!(Test-Path "$DownloadDirectory\$UpdateFile")) {
                    Write-Host "$($Update.OriginUri)" -ForegroundColor Gray
                    Start-BitsTransfer -Source $($Update.OriginUri) -Destination "$DownloadDirectory\$UpdateFile"
                }
            }
        }
    }

    END {}
}