# Constants
Set-Variable -Option Constant "RuntimePackageName" "dnx"
Set-Variable -Option Constant "RuntimeShortName" "DNX"
Set-Variable -Option Constant "RuntimeFolderName" ".dnx"
Set-Variable -Option Constant "CommandName" "dnvm"
Set-Variable -Option Constant "VersionManagerName" ".NET Version Manager"
Set-Variable -Option Constant "DefaultFeed" "https://www.myget.org/F/aspnetvnext/api/v2"
Set-Variable -Option Constant "CrossGenCommand" "dnx-crossgen"
Set-Variable -Option Constant "HomeEnvVar" "DNX_HOME"
Set-Variable -Option Constant "UserHomeEnvVar" "DNX_USER_HOME"
Set-Variable -Option Constant "FeedEnvVar" "DNX_FEED"
Set-Variable -Option Constant "PackageManagerName" "dnu.cmd"
Set-Variable -Option Constant "RuntimeHostName" "dnx.exe"

function Write-Banner {
    param($Message)

    Write-Host -ForegroundColor Green "===== $Message ====="
}

filter Write-CommandOutput {
    param($Prefix)

    Write-Host -ForegroundColor Magenta -NoNewLine "$($Prefix): "
    Write-Host $_
}

function Remove-EnvVar($var) {
    $path = "Env:\$var"
    if(Test-Path $path) {
        del $path
    }
}

function GetRuntimesOnPath {
    param($runtimeHome)
    if(!$runtimeHome) {
        $runtimeHome = (cat "env:\$UserHomeEnvVar")
    }

    if($env:PATH) {
        $paths = $env:PATH.Split(";")
        if($paths) {
            @($paths | Where { $_.StartsWith("$runtimeHome\runtimes") })
        }
    }
}

function GetActiveRuntimePath {
    param($runtimeHome)
    GetRuntimesOnPath $runtimeHome | Select -First 1
}

function GetActiveRuntimeName {
    param($runtimeHome)
    if(!$runtimeHome) {
        $runtimeHome = (cat "env:\$UserHomeEnvVar")
    }
    $activeRuntime = GetActiveRuntimePath $runtimeHome
    if($activeRuntime) {
        $activeRuntime.Replace("$runtimeHome\runtimes\", "").Replace("\bin", "")
    }
}

function GetRuntimeName {
    param($clr, $arch, $os = "win", $ver = $TestRuntimeVersion)
    if($clr -eq "mono") {
        "$RuntimePackageName-mono.$($ver.ToLowerInvariant())"
    } else {
        "$RuntimePackageName-$($clr.ToLowerInvariant())-$($os.ToLowerInvariant())-$($arch.ToLowerInvariant()).$($ver.ToLowerInvariant())"
    }
}

# Borrowed from dnvm itself, but we can't really use that one so unfortunately we have to use copy-pasta :)
# Modified slightly to take in a Proxy value so that it can be defined separately from the Proxy parameter
function Add-Proxy-If-Specified {
param(
  [System.Net.WebClient] $wc,
  [string] $Proxy
)
  if(!$Proxy) {
    $Proxy = $env:http_proxy
  }
  if ($Proxy) {
    $wp = New-Object System.Net.WebProxy($Proxy)
    $pb = New-Object UriBuilder($Proxy)
    if (!$pb.UserName) {
        $wp.Credentials = [System.Net.CredentialCache]::DefaultCredentials
    } else {
        $wp.Credentials = New-Object System.Net.NetworkCredential($pb.UserName, $pb.Password)
    }
    $wc.Proxy = $wp
  }
}

function Get-FileHash
{
    param ([string] $Path)

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf))
    {
        return $null
    }

    $item = Get-Item -LiteralPath $Path
    if ($item -isnot [System.IO.FileSystemInfo])
    {
        return $null
    }

    $stream = $null

    try
    {
        $sha = New-Object System.Security.Cryptography.SHA256CryptoServiceProvider
        $stream = $item.OpenRead()
        $bytes = $sha.ComputeHash($stream)
        return [convert]::ToBase64String($bytes)
    }
    finally
    {
        if ($null -ne $stream) { $stream.Close() }
        if ($null -ne $sha)    { $sha.Clear() }
    }
}
