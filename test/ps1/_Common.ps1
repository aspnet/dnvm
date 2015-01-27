# Constants
Set-Variable -Option Constant "RuntimePackageName" "kre"
Set-Variable -Option Constant "RuntimeFriendlyName" "K Runtime"
Set-Variable -Option Constant "RuntimeShortName" "KRE"
Set-Variable -Option Constant "RuntimeFolderName" ".k"
Set-Variable -Option Constant "CommandName" "kvm"
Set-Variable -Option Constant "VersionManagerName" "K Version Manager"
Set-Variable -Option Constant "DefaultFeed" "https://www.myget.org/F/aspnetvnext/api/v2"
Set-Variable -Option Constant "CrossGenCommand" "k-crossgen"
Set-Variable -Option Constant "HomeEnvVar" "KRE_HOME"
Set-Variable -Option Constant "UserHomeEnvVar" "KRE_USER_HOME"
Set-Variable -Option Constant "FeedEnvVar" "KRE_FEED"
Set-Variable -Option Constant "PackageManagerName" "kpm.cmd"
Set-Variable -Option Constant "RuntimeExecutableName" "k.cmd"
Set-Variable -Option Constant "RuntimeHostName" "klr.exe"

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
    param($clr, $arch, $ver = $TestRuntimeVersion)
    "$RuntimePackageName-$($clr.ToLowerInvariant())-win-$($arch.ToLowerInvariant()).$($ver.ToLowerInvariant())"
}

# Borrowed from kvm itself, but we can't really use that one so unfortunately we have to use copy-pasta :)
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