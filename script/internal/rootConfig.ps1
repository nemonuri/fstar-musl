
class RootConfig {
    [string]$fstarExe = ""
    [string]$z3Exe = ""
    [string[]]$fstarLibs = @()
}

class RootConfigState {
    [bool] $_exist = $false
    [bool] $isValidJson = $false
    [bool] $hasFStarExe = $false
    [bool] $hasZ3Exe = $false
    [bool] $hasFStarLibs = $false
}

function New-DesiredRootConfigState {
    [OutputType([RootConfigState])] param ()

    [RootConfigState]@{
        _exist = $true
        isValidJson = $true
        hasFStarExe = $true
        hasZ3Exe = $true
        hasFStarLibs = $true
    }
}

function New-RootConfigComment {
    @{
        fstarExe = "Path for F* binary. F* download link: https://github.com/FStarLang/FStar/releases"
        z3Exe = "Path for Z3 binary."
        fstarLibs = "Pathes for default F* libraries."
    }
}

function ConvertTo-RootConfigState {
    [OutputType([RootConfigState])]
    param (
        [string] $Path
    )

    [RootConfigState]$rcs = [RootConfigState]::new()

    [bool]$exist = (Test-Path $Path -PathType Leaf)
    if (-not $exist) {
        return $rcs
    }
    $rcs._exist = $exist

    [bool]$isValidJson = (Test-Json -Path $Path)
    if (-not $isValidJson) {
        return $rcs
    }
    $rcs.isValidJson = $isValidJson

    # Convert json string file to RootConfig object
    $rc = (Get-Content $Path | ConvertFrom-Json)

    [bool]$hasFStarExe = ($null -ne $rc.fstarExe)
    if (-not $hasFStarExe) { return $rcs }
    $rcs.hasFStarExe = $hasFStarExe

    [bool]$hasZ3Exe = ($null -ne $rc.z3Exe)
    if ($hasZ3Exe) { 
        $rcs.hasZ3Exe = $hasZ3Exe
    }
    
    [bool]$hasFStarLibs = ($null -ne $rc.fstarLibs)
    if ($hasFStarLibs) { 
        $rcs.hasFStarLibs = $hasFStarLibs
    }

    return $rcs
}

class RootConfigWithComment : RootConfig {
    [psobject]$_comment = $null
}

function Set-DesiredRootConfigState {
    [OutputType([RootConfigState])]
    param (
        [string] $Path
    )
    
    [RootConfigState]$des = (New-DesiredRootConfigState)
    [RootConfigState]$cur = (ConvertTo-RootConfigState $Path)

    if (($des._exist -ne $cur._exist) -or ($des.isValidJson -ne $cur.isValidJson)) {
        if ($des._exist -eq $false) { throw "Not supported." }
        if ($des.isValidJson -eq $false) { throw "Not supported." }

        $newRc = [RootConfigWithComment]::new()
        $newRc._comment = (New-RootConfigComment)
        ConvertTo-Json $newRc | Out-File $Path

        $cur._exist = $true
        $cur.isValidJson = $true
    }

    $rc = Get-Content $Path | ConvertFrom-Json -AsHashtable

    if ($des.hasFStarExe -ne $cur.hasFStarExe) {
        if ($des.hasFStarExe -eq $false) { throw "Not supported." }
        $rc.fstarExe = ""
        $cur.hasFStarExe = $true
    }

    if ($des.hasZ3Exe -ne $cur.hasZ3Exe) {
        if ($des.hasZ3Exe -eq $false) { throw "Not supported." }
        $rc.z3Exe = ""
        $cur.hasZ3Exe = $true
    }

    if ($des.hasFStarLibs -ne $cur.hasFStarLibs) {
        if ($des.hasFStarLibs -eq $false) { throw "Not supported." }
        $rc.fstarLibs = @()
        $cur.hasFStarLibs = $true
    }

    $rc | ConvertTo-Json | Out-File $Path

    return $cur
}