# "Constants"
$PackageManagerName = "kpm"
$RuntimeExecutableName = "k"

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
    param($dotnetHome)
    if(!$dotnetHome) {
        $dotnetHome = $env:DOTNET_USER_PATH
    }

    if($env:PATH) {
        $paths = $env:PATH.Split(";")
        if($paths) {
            @($paths | Where { $_.StartsWith("$dotnetHome\runtimes") })
        }
    }
}

function GetActiveRuntimePath {
    param($dotnetHome)
    GetRuntimesOnPath $dotnetHome | Select -First 1
}

function GetActiveRuntimeName {
    param($dotnetHome)
    if(!$dotnetHome) {
        $dotnetHome = $env:DOTNET_USER_PATH
    }
    $activeRuntime = GetActiveRuntimePath $dotnetHome
    if($activeRuntime) {
        $activeRuntime.Replace("$dotnetHome\runtimes\", "").Replace("\bin", "")
    }
}

function GetRuntimeName {
    param($clr, $arch, $ver = $TestDotNetVersion)
    "dotnet-$($clr.ToLowerInvariant())-win-$($arch.ToLowerInvariant()).$($ver.ToLowerInvariant())"
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