
class FstConfig {
    [string] $fstar_exe = ""
    [string[]] $options = @()
    [string[]] $include_dirs = @()
}

class FstConfigState {
    [bool] $_exist = $false
    [bool] $hasFStarExe = $false
    [bool] $hasOptions = $false
    [bool] $hasIncludeDirs = $false
    [bool] $isFStarExeMatching = $false
    [bool] $containsZ3Exe = $false
    [bool] $isZ3ExeMatching = $false
}
