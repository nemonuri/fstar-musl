
# https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/v3.1.0/outputs/resource/test.simple.json
class TestSimpleOutput {
    [psobject] $desiredState
    [psobject] $actualState
    [bool] $inDesiredState
    [string[]] $differingProperties = @();
}

function Invoke-DscTest {
    [OutputType([TestSimpleOutput])]
    param ([psobject] $Desired, [psobject] $Actual)

    $names = $Desired | Get-Member -MemberType Property | ForEach-Object { $_.Name }

    [string[]]$diffs = @()
    foreach ($name in $names) {
        if ($Desired.$name -ne $Actual.$name) {
            $diffs += $name
        }
    }

    return [TestSimpleOutput]@{
        desiredState = $Desired
        actualState = $Actual
        inDesiredState = ($diffs.Count -eq 0)
        differingProperties = $diffs
    }
}

# https://raw.githubusercontent.com/PowerShell/DSC/main/schemas/v3.1.0/outputs/resource/set.simple.json
class SetSimpleOutput {
    [psobject] $beforeState
    [psobject] $afterState
    [string[]] $changedProperties = @();
}

function New-DscSetOutput {
    [OutputType([SetSimpleOutput])]
    param ([psobject] $Before, [psobject] $After)

    $names = $Before | Get-Member -MemberType Property | ForEach-Object { $_.Name }

    [string[]]$changes = @()
    foreach ($name in $names) {
        if ($Desired.$name -ne $Actual.$name) {
            $changes += $name
        }
    }

    return [SetSimpleOutput]@{
        beforeState = $Before
        afterState = $After
        changedProperties = $changes
    }
}