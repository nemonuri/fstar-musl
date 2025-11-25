
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

$cfg = [MetaConfig]::new()

$rootPath = Join-Path $PSScriptRoot ".." -Resolve

$rootConfigPath = Join-Path $rootPath $cfg.rootConfigfileName

#--- test and set root config file ---
Write-HostWithTime "Test $($cfg.rootConfigfileName)"
$testOutput = Invoke-DscTest (New-DesiredRootConfigState) (ConvertTo-RootConfigState $rootConfigPath)
Out-Result $testOutput

if (($Mode -eq 'Set') -and (-not $testOutput.inDesiredState)) {
    Write-HostWithTime "Set $($cfg.rootConfigfileName)"
    $setOutput = New-DscSetOutput (New-DesiredRootConfigState) (Set-DesiredRootConfigState $rootConfigPath)
    Out-Result $setOutput 
}
#---|
