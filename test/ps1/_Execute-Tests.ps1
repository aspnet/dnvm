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
    [string]$OutputFile = $null,
    [string]$OutputFormat = $null,
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

# Set defaults
if(!$PesterPath) { $PesterPath = Join-Path $PSScriptRoot ".pester" }
if(!$TestsPath) { $TestsPath = Join-Path $PSScriptRoot "tests" }
if(!$KvmPath) { $KvmPath = Convert-Path (Join-Path $PSScriptRoot "../../src/kvm.ps1") }
if(!$TestWorkingDir) { $TestWorkingDir = Join-Path $PSScriptRoot ".testwork" }
if(!$TestAppsDir) { $TestAppsDir = Convert-Path (Join-Path $PSScriptRoot "../apps") }

# Configure the KREs we're going to use in testing. The actual KRE doesn't matter since we're only testing
# that KVM can find it, download it and unpack it successfully. We do run an app in the KRE to do that sanity
# test, but all we care about in these tests is that the app executes.
$env:KRE_FEED = "https://www.myget.org/F/aspnetmaster/api/v2"
$TestKreVersion = "1.0.0-beta1"
$specificNupkgUrl = "https://www.myget.org/F/aspnetmaster/api/v2/package/KRE-CLR-x86/1.0.0-alpha4"
$specificNupkgName = "KRE-CLR-x86.1.0.0-alpha4.nupkg"
$specificNuPkgFxName = "Asp.Net,Version=v5.0"

# Set up context
$kvm = $KvmPath

# Create test working directory
if(Test-Path "$TestWorkingDir\kre") {
    Write-Banner "Wiping old test working area"
    del -rec -for "$TestWorkingDir\kre"
}

if(!(Test-Path $TestWorkingDir)) {
    mkdir $TestWorkingDir | Out-Null
}

# Import the module and set up test environment
Import-Module "$PesterPath\Pester.psm1"

# Turn on Debug logging if requested
if($Debug) {
    $oldDebugPreference = $DebugPreference
    $DebugPreference = "Continue"
}

# Unset KRE_HOME for the test
$oldKreHome = $env:KRE_HOME
Remove-EnvVar KRE_HOME

# Unset KRE_TRACE for the test
Remove-EnvVar KRE_TRACE

# Unset PATH for the test
Remove-EnvVar PATH

# Set up the user/global install directories to be inside the test work area
$env:USER_KRE_PATH = "$TestWorkingDir\kre\user"
mkdir $env:USER_KRE_PATH | Out-Null

$env:GLOBAL_KRE_PATH = "$TestWorkingDir\kre\global"
mkdir $env:GLOBAL_KRE_PATH | Out-Null

# Helper function to run kvm and capture stuff.
$kvmout = $null
$kvmexit = $null
function runkvm {
    $kvmout = $null
    & $kvm -AssumeElevated -OutputVariable kvmout -Quiet @args -ErrorVariable kvmerr -ErrorAction SilentlyContinue
    $kvmexit = $LASTEXITCODE
    
    if($Debug) {
        $kvmout | Write-CommandOutput kvm
    }

    # Push the values up a scope
    Set-Variable kvmout $kvmout -Scope 1
    Set-Variable kvmexit $kvmexit -Scope 1
    Set-Variable kvmerr $kvmerr -Scope 1
}

# Fetch a nupkg to use for the 'kvm install <path to nupkg>' scenario
Write-Banner "Fetching test prerequisites"

$downloadDir = Join-Path $TestWorkingDir "downloads"
if(!(Test-Path $downloadDir)) { mkdir $downloadDir | Out-Null }
$specificNupkgPath = Join-Path $downloadDir $specificNupkgName
if(!(Test-Path $specificNupkgPath)) {
    Invoke-WebRequest $specificNupkgUrl -OutFile $specificNupkgPath
}

# Run the tests!
# Powershell complains if we pass null in for -OutputFile :(
Write-Banner "Running Pester Tests in $TestsPath"
if($OutputFile) {
    $result = Invoke-Pester `
        -Path $TestsPath `
        -TestName $TestName `
        -Tag $Tag `
        -Strict:$Strict `
        -Quiet:$Quiet `
        -OutputFile $OutputFile `
        -OutputFormat $OutputFormat `
        -PassThru
} else {
    $result = Invoke-Pester `
        -Path $TestsPath `
        -TestName $TestName `
        -Tag $Tag `
        -Strict:$Strict `
        -Quiet:$Quiet `
        -PassThru
}

function TeamCityEscape($str) {
    $str.Replace("|", "||").Replace("'", "|'").Replace("`n", "|n").Replace("`r", "|r").Replace("[", "|[").Replace("]", "|]")
}

# Generate TeamCity Output
if($TeamCity) {
    $result.TestResult | Group-Object Describe | ForEach-Object {
        $describe = TeamCityEscape $_.Name
        Write-Host "##teamcity[testSuiteStarted name='$describe']"
        $_.Group | Group-Object Context | ForEach-Object {
            $context = TeamCityEscape $_.Name
            Write-Host "##teamcity[testSuiteStarted name='$context']"
            $_.Group | ForEach-Object {
                $name = "It $(TeamCityEscape $_.Name)"
                $message = TeamCityEscape $_.FailureMessage
                Write-Host "##teamcity[testStarted name='$name']"
                switch ($_.Result) {
                    Skipped
                    {
                        Write-Host "##teamcity[testIgnored name='$name' message='$message']"
                    }
                    Pending
                    {
                        Write-Host "##teamcity[testIgnored name='$name' message='$message']"
                    }
                    Failed
                    {
                        Write-Host "##teamcity[testFailed name='$name' message='$message' details='$(TeamCityEscape $_.StackTrace)']"
                    }
                }
                Write-Host "##teamcity[testFinished name='$name']"
            }
            Write-Host "##teamcity[testSuiteFinished name='$context']"
        }
        Write-Host "##teamcity[testSuiteFinished name='$describe']"
    }
}

# Set the exit code!

$host.SetShouldExit($result.FailedCount)