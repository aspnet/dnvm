$testVer = "1.0.0-beta1"
$archs=@("x86", "amd64")    # List of architectures to test
$clrs=@("CLR", "CoreCLR")   # List of runtimes to test
$crossgenned=@("mscorlib")  # List of assemblies to check native images for on CoreCLR

# We can't put Tags on "Context" in Pester, only "Describe" so use this $Fast variable to skip other archs/clrs
if($Fast) {
    $archs=@("x86")
    $clrs=@("CLR")
}

function DefineInstallTests($clr, $arch, [switch]$global) {
    $kreHome = $env:USER_KRE_PATH
    $contextName = "for user"
    $alias = "install_test_$arch_$clr"

    if($global) {
        $contextName = "globally"
        $alias = "global_$alias"
        $kreHome = $env:GLOBAL_KRE_PATH
    }

    if($clr -eq "CoreCLR") {
        $fxName = "Asp.NetCore,Version=v5.0"
    } else {
        $fxName = "Asp.Net,Version=v5.0"
    }    

    $kreName = GetKreName $clr $arch
    $kreRoot = "$kreHome\packages\$kreName"

    Context "When installing $clr on $arch $contextName" {
        It "downloads and unpacks a KRE" {
            if($global) {
                runkvm install $testVer -arch $arch -r $clr -a $alias -global
            } else {
                runkvm install $testVer -arch $arch -r $clr -a $alias
            }
        }
        It "installs the KRE into the user directory" {
            $kreRoot | Should Exist
        }
        if($clr -eq "CoreCLR") {
            It "crossgenned native assemblies" {
                $crossgenned | ForEach-Object { "$kreRoot\bin\$_.ni.dll" } | Should Exist
            }
        }
        It "can restore packages for the HelloK sample" {
            pushd "$TestAppsDir\HelloK"
            try {
                & "$kreRoot\bin\kpm.cmd" restore
            } finally {
                popd
            }
        }
        It "can run the HelloK sample" {
            pushd "$TestAppsDir\HelloK"
            try {
                $output = & "$kreRoot\bin\k.cmd" run
                $LASTEXITCODE | Should Be 0
                $fullOutput = [String]::Join("`r`n", $output)

                $fullOutput | Should Match "K is sane!"
                $fullOutput | Should Match "Runtime Framework:\s+$fxName"
            } finally {
                popd
            }
        }
        It "assigned the requested alias" {
            "$env:USER_KRE_PATH\alias\$alias.txt" | Should Exist
            "$env:USER_KRE_PATH\alias\$alias.txt" | Should ContainExactly $kreName
        }
        It "uses the new KRE" {
            GetActiveKreName $kreHome | Should Be "$kreName"
        }
    }
}

Describe "Kvm-Install" {
    $archs | ForEach-Object {
        $arch = $_
        $clrs | ForEach-Object {
            $clr = $_
            DefineInstallTests $clr $arch
            DefineInstallTests $clr $arch -global
        }
    }

    Context "When installing latest" {
        $previous = @(dir "$env:USER_KRE_PATH\packages" | select -ExpandProperty Name)
        It "downloads a KRE" {
            runkvm install latest -arch x86 -r CLR
        }
        # TODO: Check that it actually installed the latest?
    }

    Context "When installing an already-installed KRE" {
        # Clear active KRE
        runkvm use none

        $kreName = GetKreName $clrs[0] $archs[0]
        $krePath = "$env:USER_KRE_PATH\packages\$kreName"
        It "ensures the KRE is installed" {
            runkvm install $testVer -arch $archs[0] -r $clrs[0]
            $kvmout[0] | Should Match "$kreName already installed"
            $krePath | Should Exist
        }
    }

    Context "When installing a specific nupkg" {
        $name = [IO.Path]::GetFileNameWithoutExtension($specificNupkgName)
        $kreRoot = "$env:USER_KRE_PATH\packages\$name"

        It "unpacks the KRE" {
            runkvm install $specificNupkgPath
        }
        
        It "installs the KRE into the user directory" {
            $kreRoot | Should Exist
        }

        It "did not assign an alias" {
            dir "$env:USER_KRE_PATH\alias\*.txt" | ForEach-Object {
                $_ | Should Not Contain $name
            }
        }
    }
}