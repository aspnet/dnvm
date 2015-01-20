#Requires -Version 3
param(
    [string]$PesterPath = $null,
    [string]$PesterRef = "anurse/teamcity",
    [string]$PesterRepo = "https://github.com/anurse/Pester",
    [string]$TestsPath = $null,
    [string]$DotNetSdkPath = $null,
    [string]$TestName = $null,
    [string]$TestWorkingDir = $null,
    [string]$TestAppsDir = $null,
    [Alias("Tags")][string]$Tag = $null,
    [string]$OutputFile = $null,
    [string]$OutputFormat = $null,
    [string]$Proxy = $null,
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
if(!$DotNetSdkPath) { $DotNetSdkPath = Convert-Path (Join-Path $PSScriptRoot "../../src/dotnetsdk.ps1") }
if(!$TestWorkingDir) { $TestWorkingDir = Join-Path $PSScriptRoot "testwork" }
if(!$TestAppsDir) { $TestAppsDir = Convert-Path (Join-Path $PSScriptRoot "../apps") }

# Configure the Runtimes we're going to use in testing. The actual runtime doesn't matter since we're only testing
# that dotnetsdk can find it, download it and unpack it successfully. We do run an app in the runtime to do that sanity
# test, but all we care about in these tests is that the app executes.
$env:DOTNET_FEED = "https://www.myget.org/F/aspnetvnext/api/v2"
$TestDotNetVersion = "1.0.0-beta3-10924"
$specificNupkgUrl = "$($env:DOTNET_FEED)/package/dotnet-coreclr-win-x64/$TestDotNetVersion"
$specificNupkgHash = "355BD8849AE1A36AEC7614DDD7F9751B3BA612718382C1C775F634802B6D9D5D"
$specificNupkgName = "dotnet-coreclr-win-x64.$TestDotNetVersion.nupkg"
$specificNuPkgFxName = "Asp.Net,Version=v5.0"

# Set up context
$dotnetsdk = $DotNetSdkPath

# Create test working directory
if(Test-Path "$TestWorkingDir\.dotnet") {
    Write-Banner "Wiping old test working area"
    del -rec -for "$TestWorkingDir\.dotnet"
}

if(!(Test-Path $TestWorkingDir)) {
    mkdir $TestWorkingDir | Out-Null
}

# Import the module and set up test environment
Import-Module "$PesterPath\Pester.psm1"

# Turn on Debug logging if requested
if($Debug -or ($env:PS1_DEBUG -eq "1")) {
    $DebugPreference = "Continue"
    $VerbosePreference = "Continue"
}

# Unset DOTNET_HOME for the test
$oldKreHome = $env:DOTNET_HOME
Remove-EnvVar DOTNET_HOME

# Unset DOTNET_TRACE for the test
Remove-EnvVar DOTNET_TRACE

# Unset PATH for the test
Remove-EnvVar PATH

# Set up the user/global install directories to be inside the test work area
$env:DOTNET_USER_PATH = "$TestWorkingDir\.dotnet\user"
mkdir $env:DOTNET_USER_PATH | Out-Null

# Helper function to run dotnetsdk and capture stuff.
$dotnetsdkout = $null
$dotnetsdkexit = $null
function rundotnetsdk {
    $dotnetsdkout = $null
    & $dotnetsdk -Proxy:$Proxy -AssumeElevated -OutputVariable dotnetsdkout -Quiet @args -ErrorVariable dotnetsdkerr -ErrorAction SilentlyContinue
    $dotnetsdkexit = $LASTEXITCODE

    if($Debug) {
        $dotnetsdkout | Write-CommandOutput dotnetsdk
    }

    # Push the values up a scope
    Set-Variable dotnetsdkout $dotnetsdkout -Scope 1
    Set-Variable dotnetsdkexit $dotnetsdkexit -Scope 1
    Set-Variable dotnetsdkerr $dotnetsdkerr -Scope 1
}

# Fetch a nupkg to use for the 'dotnetsdk install <path to nupkg>' scenario
Write-Banner "Fetching test prerequisites"

$downloadDir = Join-Path $TestWorkingDir "downloads"
if(!(Test-Path $downloadDir)) { mkdir $downloadDir | Out-Null }
$specificNupkgPath = Join-Path $downloadDir $specificNupkgName

# If the test package exists
if(Test-Path $specificNupkgPath) {
    # Test it against the expected hash
    if((Get-FileHash -Algorithm SHA256 $specificNupkgPath).Hash -ne $specificNupkgHash) {
        # Failed to match, kill it with fire!
        Write-Host "Test prerequisites are corrupt, redownloading."
        rm -for $specificNupkgPath
    }
}

# Check if the the test package exists again (since we might have deleted it above)
if(!(Test-Path $specificNupkgPath)) {
    # It doesn't, redownload it
    $wc = New-Object System.Net.WebClient
    Add-Proxy-If-Specified $wc $Proxy
    $wc.DownloadFile($specificNupkgUrl, $specificNupkgPath)

    # Test it against the expected hash
    $actualHash = (Get-FileHash -Algorithm SHA256 $specificNupkgPath).Hash
    if($actualHash -ne $specificNupkgHash) {
        # Failed to match, we downloaded a corrupt package??
        throw "Test prerequisite $specificNupkgUrl failed to download. The hash '$actualHash' does not match the expected value."
    }
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
    if($str) {
        $str.Replace("|", "||").Replace("'", "|'").Replace("`n", "|n").Replace("`r", "|r").Replace("[", "|[").Replace("]", "|]")
    }
}

# Generate TeamCity Output
if($TeamCity) {
    Write-Host "##teamcity[testSuiteStarted name='ps1']"
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
    Write-Host "##teamcity[testSuiteFinished name='ps1']"
}

# Set the exit code!

$host.SetShouldExit($result.FailedCount)