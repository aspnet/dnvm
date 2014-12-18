#Requires -Version 3
<#
.SYNOPSIS
    Runs the tests for kvm

.PARAMETER PesterPath
    The path to the root of the Pester (https://github.com/pester/Pester) module (optional)

.PARAMETER PesterRef
    A git ref (branch, tag or commit id) to check out in the pester repo (optional)

.PARAMETER PesterRepo
    The repository to clone Pester from (optional)

.PARAMETER TestsPath
    The path to the folder containing Tests to run (optional)

.PARAMETER KvmPath
    The path to the kvm.ps1 script to test (optional)

.PARAMETER TestName
    The name of a specific test to run (optional)

.PARAMETER TestWorkingDir
    The directory in which to place KREs downloaded during the tests (optional)

.PARAMETER TestAppsDir
    The directory in which test K apps live (optional)

.PARAMETER Tag
    Run only tests with the specified tag (optional)

.PARAMETER Quiet
    Output minimal console messages

.PARAMETER Debug
    Output extra console messages

.PARAMETER TeamCity
    Output TeamCity test outcome markers
#>
param(
    [string]$PesterPath = $null,
    [string]$PesterRef = "3.2.0",
    [string]$PesterRepo = "https://github.com/pester/Pester",
    [string]$TestsPath = $null,
    [string]$KvmPath = $null,
    [string]$TestName = $null,
    [string]$TestWorkingDir = $null,
    [string]$TestAppsDir = $null,
    [Alias("Tags")][string]$Tag = $null,
    [switch]$Quiet,
    [switch]$Debug,
    [switch]$TeamCity)

. "$PSScriptRoot\_Common.ps1"

Write-Banner "Starting child shell"

# Crappy that we have to duplicate things here...
# Build a string that should basically match the argument string used to call us
$childArgs = @()
$PSBoundParameters.Keys | ForEach-Object {
    $key = $_
    $value = $PSBoundParameters[$key]
    if($value -is [switch]) {
        if($value.IsPresent) {
            $childArgs += @("-$key")
        }
    } else {
        $childArgs += @("-$key",$value)
    }
}

# Launch the script that will actually run the tests in a new shell
& powershell -NoProfile -NoLogo -Command "& `"$PSScriptRoot\_Execute-Tests.ps1`" $childArgs -RunningInNewPowershell"

exit $LASTEXITCODE