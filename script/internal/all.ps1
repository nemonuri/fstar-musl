
. $PSScriptRoot/metaConfig.ps1
. $PSScriptRoot/rootConfig.ps1
. $PSScriptRoot/dsc.ps1
. $PSScriptRoot/fstConfig.ps1

function Test-Windows {
    [OutputType([bool])] param()
    
    ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT)
}

function Format-Exe {
    [OutputType([string])]
    param ([string] $ExePath)
    
    if (Test-Windows) {
        [System.IO.Path]::ChangeExtension($ExePath, '.exe')
    } else {
        [System.IO.Path]::ChangeExtension($ExePath, $null)
    }
}

function Write-HostWithTime([string] $Text) {
    Write-Host "[$(Get-Date -Format 'yyyy-MM-ddTHH:mm:ssz')] $Text"
}

function Get-Meta {
    Import-PowerShellDataFile "$PSScriptRoot/data/meta.psd1"
}