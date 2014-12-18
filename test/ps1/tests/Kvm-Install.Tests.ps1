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
    try {
        DefineInstallTests "CLR" "x86"
        DefineInstallTests "CLR" "amd64"
        DefineInstallTests "CoreCLR" "x86" -noNative
        DefineInstallTests "CoreCLR" "amd64"
        DefineInstallTests "CLR" "x86" -global

        Context "When installing a non-existant KRE version" {
            runkvm install "0.0.1-thisisnotarealKRE"

            It "returns a non-zero exit code" {
                $kvmexit | Should Not Be 0
            }

            It "throws a 404 error" {
                $kvmerr[0].Exception.Message | Should Be 'Exception calling "DownloadFile" with "2" argument(s): "The remote server returned an error: (404) Not Found."'
            }
        }

        Context "When no architecture is specified" {
            runkvm install $TestKreVersion -r CLR
            $kreName = GetKreName -clr CLR -arch x86

            It "uses x86" {
                $kvmout[0] | Should Be "$kreName already installed."
            }
        }

        Context "When no runtime is specified" {
            runkvm install $TestKreVersion -arch x86
            $kreName = GetKreName -clr CLR -arch x86

            It "uses CLR" {
                $kvmout[0] | Should Be "$kreName already installed."
            }
        }

        Context "When neither architecture no runtime is specified" {
            runkvm install $TestKreVersion
            $kreName = GetKreName -clr CLR -arch x86

            It "uses x86/CLR" {
                $kvmout[0] | Should Be "$kreName already installed."
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

            $kreName = GetKreName "CLR" "x86"
            $krePath = "$env:USER_KRE_PATH\packages\$kreName"
            It "ensures the KRE is installed" {
                runkvm install $TestKreVersion -x86 -r "CLR"
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
    finally {
        # Clean the global directory
        del -rec -for $env:GLOBAL_KRE_PATH
    }
}