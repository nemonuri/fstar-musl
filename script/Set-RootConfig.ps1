
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3.0

#--- classes ---

# https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/v3.1.0/outputs/resource/test.simple.json
class TestSimpleOutput {
    [psobject] $desiredState
    [psobject] $actualState
    [bool] $inDesiredState
    [string[]] $differingProperties = @();
}

# https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/v3.1.0/outputs/resource/set.simple.json
class SetSimpleOutput {
    [psobject] $beforeState
    [psobject] $afterState
    [string[]] $changedProperties = @();
}

class FileState {
    [bool] $_exist
    [bool] $isValidJson
    [bool] $hasPropertyFStarRoot
}

#---|

#--- functions ---
function Write-HostWithTime([string] $Text) {
    Write-Host "[$(Get-Date -Format 'yyyyMMddTHHmmssz')] $Text"
}

function Test-ArrayDiff([string[]] $MaybeContains, [string[]] $MaybeNotContains, [string] $Item) {
    ($MaybeContains -contains $Item) -and ($MaybeNotContains -notcontains $Item)
}
#---|

#--- meta-config ---
$cfg = @{
    fileName = '.root-config'
}
#---|

$rootPath = Join-Path $PSScriptRoot ".." -Resolve

$rootConfigPath = Join-Path $rootPath $cfg.fileName



function New-FileContent {
    return @{
        _comment = @{
            fstarRoot = "Root directory of F* binary. F* download link: https://github.com/FStarLang/FStar/releases"
        };
        fstarRoot = ""
    }
}

function Set-File {

    #--- test ---
    Write-HostWithTime "Test File"

    $desired = [FileState]@{ _exist = $true; isValidJson = $true; hasPropertyFStarRoot = $true }

    $actual = @{}
    $actual._exist = (Test-Path $rootConfigPath -PathType Leaf)
    $actual.isValidJson = $false
    if ($actual._exist -and (Test-Json -Path $rootConfigPath)) {
        $actual.isValidJson = $true
    }
    $actual.hasPropertyFStarRoot = $false
    if ($actual.isValidJson) {
        $v = ConvertFrom-Json $rootConfigPath
        if (-not ($null -eq $v.fstarRoot)) {
            $actual.hasPropertyFStarRoot = $true
        }
    }
    
    $diff = @()
    $toCompares = @('_exist','isValidJson','hasPropertyFStarRoot')
    foreach ($cur in $toCompares) {
        if (-not ($desired.$cur -eq $actual.$cur)) {
            $diff += $cur
        }
    }

    $r = [TestSimpleOutput]@{
        desiredState = $desired
        actualState = $actual
        inDesiredState = ($diff.Count -eq 0)
        differingProperties = $diff
    }

    ConvertTo-Json $r | Write-Host
    #---|

    #--- set ---
    if (-not $r.inDesiredState) {
        Write-HostWithTime "Set File"

        $changed = @()
        $afterState = @{}

        if (Test-ArrayDiff $r.differingProperties $changed 'isValidJson') {
            New-FileContent | ConvertTo-Json | Out-File $rootConfigPath
            if ($r.differingProperties -contains '_exist') {
                $changed += '_exist'
            }
            $changed = $changed + @('isValidJson','hasPropertyFStarRoot')
            $afterState._exist = $true
            $afterState.isValidJson = $true
            $afterState.hasPropertyFStarRoot = $true
        }

        if (Test-ArrayDiff $r.differingProperties $changed 'hasPropertyFStarRoot') {
            $v = Get-Content $rootConfigPath | ConvertFrom-Json
            $v.fstarRoot = ""
            ConvertTo-Json $v | Out-File $rootConfigPath

            $changed += 'hasPropertyFStarRoot'
            $afterState.hasPropertyFStarRoot = $true
        }
        
        $r2 = [SetSimpleOutput]@{
            beforeState = $actual
            afterState = $afterState
            changedProperties = $changed
        }

        ConvertTo-Json $r2 | Write-Host
    }
    #---|
}

Set-File
# test
#$isRootConfigExist = (Test-Path $rootConfigPath -PathType Leaf)

# set
#---|
