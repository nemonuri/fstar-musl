
$ErrorActionPreference = 'Stop'
Set-StrictMode -Off

. $PSScriptRoot/internal/all.ps1

# meta-config
$meta = Get-Meta

#--- Test root config ---
[TestSimpleOutput]$testOutput = & $PSScriptRoot/Set-RootConfig.ps1 -Mode 'Test' -PassThru
if ($testOutput.inDesiredState -ne $true) {
    Write-Error "Test $($meta.RootConfig) failed. Run Set-RootConfig.ps1 first."
    exit 1
} else {
    Write-HostWithTime "Test $($meta.RootConfig) passed."
}
#---|

$rc = Get-Content -Path (Join-Path $PSScriptRoot '..' $meta.RootConfig) | ConvertFrom-Json

#--- Validate root config ---
class RootConfigInfo {
    [bool] $isFStarExeValid = $false
    [bool] $isZ3ExeValid = $false
    [bool] $areAllFStarLibValid = $false
}

function Confirm-RootConfig {
    [OutputType([TestSimpleOutput])] param()

    $des = [RootConfigInfo]@{
        isFStarExeValid = $true
        isZ3ExeValid = $true
        areAllFStarLibValid = $true
    }

    $cur = [RootConfigInfo]::new()

    (& $rc.fstarExe 2>&1) | Out-Null
    $cur.isFStarExeValid = ($LASTEXITCODE -ne 0)

    (& $rc.z3Exe 2>&1) | Out-Null
    $cur.isZ3ExeValid = ($LASTEXITCODE -ne 0)

    $cur.areAllFStarLibValid = $true
    foreach ($lib in $rc.fstarLibs) {
        if (-not (Test-Path $lib -PathType 'Container')) {
            $cur.areAllFStarLibValid = $false
            break
        }
    }

    $testOutput = Invoke-DscTest $des $cur 
    $testOutput | ConvertTo-Json | Write-Host
    return $testOutput
} 

if (-not (Confirm-RootConfig).inDesiredState) {
    Write-Error "Confirm $($meta.RootConfig) failed."
    exit 1
} else {
    Write-HostWithTime "Confirm $($meta.RootConfig) passed."
}
#---|

#--- set fst.config.json ---
Write-HostWithTime "Set $($meta.FstConfig)"

$fc = [FstConfig]@{
    fstar_exe = $rc.fstarExe
    options = @('--smt', $rc.z3Exe)
    include_dirs = $rc.fstarLibs
}

$fc | ConvertTo-Json | Out-File -FilePath (Join-Path $PSScriptRoot '..' $meta.FstConfig)
#---|
