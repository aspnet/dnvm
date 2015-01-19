# "Constants"
$packageManagerName = "kpm"

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
        $dotnetHome = $env:USER_DOTNET_PATH
    }

    if($env:PATH) {
        $paths = $env:PATH.Split(";")
        if($paths) {
            @($paths | Where { $_.StartsWith("$dotnetHome\packages") })
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
        $dotnetHome = $env:USER_DOTNET_PATH
    }
    $activeKre = GetActiveRuntimePath $dotnetHome
    if($activeKre) {
        $activeKre.Replace("$dotnetHome\packages\", "").Replace("\bin", "")
    }
}

function GetKreName {
    param($clr, $arch, $ver = $TestKreVersion)
    "DotNet-$clr-$arch.$ver"
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