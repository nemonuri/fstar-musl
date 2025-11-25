
$ErrorActionPreference = 'Stop'
Set-StrictMode -Off

. $PSScriptRoot/internal/all.ps1

#--- functions ---
function Write-HostWithTime([string] $Text) {
    Write-Host "[$(Get-Date -Format 'yyyyMMddTHHmmssz')] $Text"
}
#---|

$cfg = [MetaConfig]::new()

$rootPath = Join-Path $PSScriptRoot ".." -Resolve

$rootConfigPath = Join-Path $rootPath $cfg.fileName

#--- test and set root config file ---
Write-HostWithTime "Test File"
$testOutput = Invoke-DscTest (New-DesiredRootConfigState) (ConvertTo-RootConfigState $rootConfigPath)
ConvertTo-Json $testOutput | Write-Host

if (-not $testOutput.inDesiredState) {
    Write-HostWithTime "Set File"
    $setOutput = New-DscSetOutput (New-DesiredRootConfigState) (Set-DesiredRootConfigState $rootConfigPath)
    ConvertTo-Json $setOutput | Write-Host
}
#---|
