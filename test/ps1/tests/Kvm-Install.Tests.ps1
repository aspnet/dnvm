$crossgenned=@("mscorlib")  # List of assemblies to check native images for on CoreCLR

function DefineInstallTests($clr, $arch, [switch]$global, [switch]$noNative) {
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

    $nativeText = ""
    if($noNative) {
        $nativeText = " (without building native images)"
    }

    Context "When installing $clr on $arch $contextName$nativeText" {
        It "downloads and unpacks a KRE" {
            if($global) {
                runkvm install $TestKreVersion -arch $arch -r $clr -a $alias -global
            } elseif($noNative) {
                runkvm install $TestKreVersion -arch $arch -r $clr -a $alias -nonative    
            } else {
                runkvm install $TestKreVersion -arch $arch -r $clr -a $alias
            }
        }
        
        It "installs the KRE into the user directory" {
            $kreRoot | Should Exist
        }
        
        if($clr -eq "CoreCLR") {
            if($noNative) {
                It "did not crossgen native assemblies" {
                    $crossgenned | ForEach-Object { "$kreRoot\bin\$_.ni.dll" } | Should Not Exist
                }
            } else {
                It "crossgenned native assemblies" {
                    $crossgenned | ForEach-Object { "$kreRoot\bin\$_.ni.dll" } | Should Exist
                }
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

Describe "kvm install" -Tag "kvm-install" {
    DefineInstallTests "CLR" "x86"
    DefineInstallTests "CLR" "amd64"
    DefineInstallTests "CoreCLR" "x86" -noNative
    DefineInstallTests "CoreCLR" "amd64"
    DefineInstallTests "CLR" "x86" -global

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
            runkvm install $TestKreVersion -arch $archs[0] -r $clrs[0]
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