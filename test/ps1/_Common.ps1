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

function GetKresOnPath {
    param($kreHome)
    if(!$kreHome) {
        $kreHome = $env:USER_KRE_PATH
    }

    if($env:PATH) {
        $paths = $env:PATH.Split(";")
        if($paths) {
            @($paths | Where { $_.StartsWith("$kreHome\packages") })
        }
    }
}

function GetActiveKrePath {
    param($kreHome)
    GetKresOnPath $kreHome | Select -First 1
}

function GetActiveKreName {
    param($kreHome)
    if(!$kreHome) {
        $kreHome = $env:USER_KRE_PATH
    }
    $activeKre = GetActiveKrePath $kreHome
    if($activeKre) {
        $activeKre.Replace("$kreHome\packages\", "").Replace("\bin", "")
    }
}

function GetKreName {
    param($clr, $arch, $ver = $TestKreVersion)
    "KRE-$clr-$arch.$ver"
}