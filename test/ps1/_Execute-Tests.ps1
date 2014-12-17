#Requires -Version 3
param(
    [string]$PesterPath = $null,
    [string]$PesterRef = "anurse/teamcity",
    [string]$PesterRepo = "https://github.com/anurse/Pester",
    [string]$TestsPath = $null,
    [string]$KvmPath = $null,
    [string]$TestName = $null,
    [string]$TestWorkingDir = $null,
    [string]$TestAppsDir = $null,
    [Alias("Tags")][string]$Tag = $null,
    [switch]$Strict,
    [switch]$Quiet,
    [switch]$Debug,
    [switch]$TeamCity,

    # Cheap and relatively effective way to scare users away from running this script themselves
    [switch]$RunningInNewPowershell)

if(!$RunningInNewPowershell) {
    throw "Don't use this script to run the tests! Use Run-Tests.ps1, it sets up a new powershell instance in which to run the tests!"
}

. "$PSScriptRoot\_Common.ps1"

Write-Banner "In child shell"

# Check for commands
if(!(Get-Command git -ErrorAction SilentlyContinue)) { throw "Need git to run tests!" }

# Set defaults
if(!$PesterPath) { $PesterPath = Join-Path $PSScriptRoot ".pester" }
if(!$TestsPath) { $TestsPath = Join-Path $PSScriptRoot "tests" }
if(!$KvmPath) { $KvmPath = Convert-Path (Join-Path $PSScriptRoot "../../src/kvm.ps1") }
if(!$TestWorkingDir) { $TestWorkingDir = Join-Path $PSScriptRoot ".testwork" }
if(!$TestAppsDir) { $TestAppsDir = Convert-Path (Join-Path $PSScriptRoot "../apps") }
$TestKreVersion = "1.0.0-beta1"

# Check that Pester is present
Write-Banner "Ensuring Pester is at $PesterRef"
if(!(Test-Path $PesterPath)) {
    git clone $PesterRepo $PesterPath 2>&1 | Write-CommandOutput "git"
}

# Get the right tag checked out
pushd $PesterPath
git checkout $PesterRef 2>&1 | Write-CommandOutput "git"
popd

# Set up context
$kvm = $KvmPath

Write-Host "Using kvm: $kvm"

# Create test area
if(Test-Path "$TestWorkingDir\kre") {
    Write-Banner "Wiping old test working area"
    del -rec -for "$TestWorkingDir\kre"
}

if(!(Test-Path $TestWorkingDir)) {
    mkdir $TestWorkingDir | Out-Null
}

# Import the module and set up test environment
Import-Module "$PesterPath\Pester.psm1"

if($Debug) {
    $oldDebugPreference = $DebugPreference
    $DebugPreference = "Continue"
}

function Remove-EnvVar($var) {
    $path = "Env:\$var"
    if(Test-Path $path) {
        del $path
    }
}

# Unset KRE_HOME for the test
$oldKreHome = $env:KRE_HOME
Remove-EnvVar KRE_HOME

# Unset KRE_TRACE for the test
Remove-EnvVar KRE_TRACE

$env:USER_KRE_PATH = "$TestWorkingDir\kre\user"
mkdir $env:USER_KRE_PATH | Out-Null

$env:GLOBAL_KRE_PATH = "$TestWorkingDir\kre\global"
mkdir $env:GLOBAL_KRE_PATH | Out-Null

$env:KRE_NUGET_API_URL = "https://www.myget.org/F/aspnetmaster/api/v2"

$kvmout = $null
$kvmexit = $null
function runkvm {
    $kvmout = $null
    & $kvm -AssumeElevated -OutputVariable kvmout -Quiet @args
    $kvmexit = $LASTEXITCODE
    
    if($Debug) {
        $kvmout | Write-CommandOutput kvm
    }

    # Push the values up a scope
    Set-Variable kvmout $kvmout -Scope 1
    Set-Variable kvmexit $kvmexit -Scope 1
}

Write-Banner "Fetching test prerequisites"
$specificNupkgUrl = "https://www.myget.org/F/aspnetmaster/api/v2/package/KRE-CLR-x86/1.0.0-alpha4"
$specificNupkgName = "KRE-CLR-x86.1.0.0-alpha4.nupkg"
$specificNuPkgFxName = "Asp.Net,Version=v5.0"

$downloadDir = Join-Path $TestWorkingDir "downloads"
if(!(Test-Path $downloadDir)) { mkdir $downloadDir | Out-Null }
$specificNupkgPath = Join-Path $downloadDir $specificNupkgName
if(!(Test-Path $specificNupkgPath)) {
    Invoke-WebRequest $specificNupkgUrl -OutFile $specificNupkgPath
}

Write-Banner "Running all Pester Tests in $TestsPath"
$result = Invoke-Pester -Path $TestsPath -TestName $TestName -Tag $Tag -Strict:$Strict -Quiet:$Quiet -TeamCity:$TeamCity -PassThru

$host.SetShouldExit($result.FailedCount)