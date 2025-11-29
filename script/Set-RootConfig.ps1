
[CmdletBinding()]
param (
    [ValidateSet('Test', 'Set')][string] $Mode = 'Set',
    [switch] $PassThru
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Off

. $PSScriptRoot/internal/all.ps1

#--- functions ---
function Out-Result([psobject] $InputObject) {
    if ($PassThru) {
        return $InputObject
    } else {
        ConvertTo-Json $InputObject | Write-Host
    }
}
#---|

$meta = Get-Meta

$rootPath = Join-Path $PSScriptRoot ".." -Resolve

$rootConfigPath = Join-Path $rootPath $meta.RootConfig

#--- test and set root config file ---
Write-HostWithTime "Test $($meta.RootConfig)"
$testOutput = Invoke-DscTest (New-DesiredRootConfigState) (ConvertTo-RootConfigState $rootConfigPath)
Out-Result $testOutput

if (($Mode -eq 'Set') -and (-not $testOutput.inDesiredState)) {
    Write-HostWithTime "Set $($meta.RootConfig)"
    $setOutput = New-DscSetOutput (New-DesiredRootConfigState) (Set-DesiredRootConfigState $rootConfigPath)
    Out-Result $setOutput 
}
#---|
