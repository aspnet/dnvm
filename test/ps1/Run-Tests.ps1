#Requires -Version 3
<#
.SYNOPSIS
    Runs the tests for kvm

.PARAMETER PesterPath
    The path to the root of the Pester (https://github.com/pester/Pester) module

.PARAMETER PesterRef
    A git ref (branch, tag or commit id) to check out in the pester repo

.PARAMETER PesterRepo
    The repository to clone Pester from (defaults to https://github.com/pester/Pester)
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
    [switch]$Strict,
    [switch]$Quiet,
    [switch]$Fast,
    [switch]$Debug)

. "$PSScriptRoot\_Common.ps1"

Write-Banner "Starting child shell"

# Crappy that we have to duplicate things here...
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

& powershell -NoProfile -NoLogo -File "$PSScriptRoot\_Execute-Tests.ps1" @childArgs -RunningInNewPowershell