#Requires -Version 3
<#
.SYNOPSIS
    Runs the tests for dnvm

.PARAMETER PesterPath
    The path to the root of the Pester (https://github.com/pester/Pester) module (optional)

.PARAMETER PesterRef
    A git ref (branch, tag or commit id) to check out in the pester repo (optional)

.PARAMETER PesterRepo
    The repository to clone Pester from (optional)

.PARAMETER TestsPath
    The path to the folder containing Tests to run (optional)

.PARAMETER TargetPath
    The path to the script to test (optional)

.PARAMETER TestName
    The name of a specific test to run (optional)

.PARAMETER TestWorkingDir
    The directory in which to place DNXes downloaded during the tests (optional)

.PARAMETER TestAppsDir
    The directory in which test apps live (optional)

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
    [string]$PesterRef = "master",
    [string]$PesterRepo = "https://github.com/pester/Pester",
    [string]$TestsPath = $null,
    [string]$TargetPath = $null,
    [string]$TestName = $null,
    [string]$TestWorkingDir = $null,
    [string]$TestAppsDir = $null,
    [Alias("Tags")][string]$Tag = $null,
    [string]$OutputFile = $null,
    [string]$OutputFormat = $null,
    [switch]$Quiet,
    [switch]$Debug,
    [switch]$TeamCity)

. "$PSScriptRoot\_Common.ps1"

# Check for necessary commands
if(!(Get-Command git -ErrorAction SilentlyContinue)) { throw "Need git to run tests!" }

if(!$PesterPath) { $PesterPath = Join-Path $PSScriptRoot ".pester" }

# Check that Pester is present
Write-Banner "Ensuring Pester is at $PesterRef"
if(!(Test-Path $PesterPath)) {
    git clone $PesterRepo $PesterPath 2>&1 | Write-CommandOutput "git"
}

# Get the right tag checked out
pushd $PesterPath
git checkout $PesterRef 2>&1 | Write-CommandOutput "git"
popd

Write-Banner "Starting child shell to run"

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
& powershell -Version 2 -NoProfile -NoLogo -Command "& `"$PSScriptRoot\_Execute-Tests.ps1`" $childArgs -RunningInNewPowershell"
& powershell -NoProfile -NoLogo -Command "& `"$PSScriptRoot\_Execute-Tests.ps1`" $childArgs -RunningInNewPowershell"
exit $LASTEXITCODE
