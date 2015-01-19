$crossgenned=@("mscorlib")  # List of assemblies to check native images for on CoreCLR

function DefineInstallTests($clr, $arch, [switch]$global, [switch]$noNative) {
    $runtimeHome = $env:USER_DOTNET_PATH
    $contextName = "for user"
    $alias = "install_test_$arch_$clr"

    if($global) {
        $contextName = "globally"
        $alias = "global_$alias"
        $runtimeHome = $env:GLOBAL_DOTNET_PATH
    }

    if($clr -eq "CoreCLR") {
        $fxName = "Asp.NetCore,Version=v5.0"
    } else {
        $fxName = "Asp.Net,Version=v5.0"
    }    

    $runtimeName = GetRuntimeName $clr $arch
    $runtimeRoot = "$runtimeHome\runtimes\$runtimeName"

    $nativeText = ""
    if($noNative) {
        $nativeText = " (without building native images)"
    }

    Context "When installing $clr on $arch $contextName$nativeText" {
        It "downloads and unpacks a KRE" {
            if($global) {
                rundotnetsdk install $TestDotNetVersion -arch $arch -r $clr -a $alias -global
            } elseif($noNative) {
                rundotnetsdk install $TestDotNetVersion -arch $arch -r $clr -a $alias -nonative    
            } else {
                rundotnetsdk install $TestDotNetVersion -arch $arch -r $clr -a $alias
            }
        }
        
        It "installs the KRE into the user directory" {
            $runtimeRoot | Should Exist
        }
        
        if($clr -eq "CoreCLR") {
            if($noNative) {
                It "did not crossgen native assemblies" {
                    $crossgenned | ForEach-Object { "$runtimeRoot\bin\$_.ni.dll" } | Should Not Exist
                }
            } else {
                It "crossgenned native assemblies" {
                    $crossgenned | ForEach-Object { "$runtimeRoot\bin\$_.ni.dll" } | Should Exist
                }
            }
        }

        It "can restore packages for the HelloK sample" {
            pushd "$TestAppsDir\TestApp"
            try {
                & "$runtimeRoot\bin\$PackageManagerName" restore
            } finally {
                popd
            }
        }
        
        It "can run the HelloK sample" {
            pushd "$TestAppsDir\TestApp"
            try {
                $output = & "$runtimeRoot\bin\$RuntimeExecutableName" run
                $LASTEXITCODE | Should Be 0
                $fullOutput = [String]::Join("`r`n", $output)

                $fullOutput | Should Match "Runtime is sane!"
                $fullOutput | Should Match "Runtime Framework:\s+$fxName"
            } finally {
                popd
            }
        }

        It "assigned the requested alias" {
            "$env:USER_DOTNET_PATH\alias\$alias.txt" | Should Exist
            "$env:USER_DOTNET_PATH\alias\$alias.txt" | Should ContainExactly $runtimeName
        }
        
        It "uses the new Runtime" {
            GetActiveRuntimeName $runtimeHome | Should Be "$runtimeName"
        }
    }
}

Describe "dotnetsdk-ps1 install" -Tag "dotnetsdk-install" {
    try {
        DefineInstallTests "CLR" "x86"
        DefineInstallTests "CLR" "amd64"
        DefineInstallTests "CoreCLR" "x86" -noNative
        DefineInstallTests "CoreCLR" "amd64"
        DefineInstallTests "CLR" "x86" -global

        Context "When installing a non-existant Runtime version" {
            rundotnetsdk install "0.0.1-thisisnotarealruntime"

            It "returns a non-zero exit code" {
                $dotnetsdkexit | Should Not Be 0
            }

            It "throws a 404 error" {
                $dotnetsdkerr[0].Exception.Message | Should Be 'Exception calling "DownloadFile" with "2" argument(s): "The remote server returned an error: (404) Not Found."'
            }
        }

        Context "When no architecture is specified" {
            rundotnetsdk install $TestDotNetVersion -r CLR
            $runtimeName = GetRuntimeName -clr CLR -arch x86

            It "uses x86" {
                $dotnetsdkout[0] | Should Be "$runtimeName already installed."
            }
        }

        Context "When no clr is specified" {
            rundotnetsdk install $TestDotNetVersion -arch x86
            $runtimeName = GetRuntimeName -clr CLR -arch x86

            It "uses Desktop CLR" {
                $dotnetsdkout[0] | Should Be "$runtimeName already installed."
            }
        }

        Context "When neither architecture nor clr is specified" {
            rundotnetsdk install $TestDotNetVersion
            $runtimeName = GetRuntimeName -clr CLR -arch x86

            It "uses x86/Desktop" {
                $dotnetsdkout[0] | Should Be "$runtimeName already installed."
            }   
        }

        Context "When installing latest" {
            $previous = @(dir "$env:USER_DOTNET_PATH\runtimes" | select -ExpandProperty Name)
            It "downloads a runtime" {
                rundotnetsdk install latest -arch x86 -r CLR
            }
            # TODO: Check that it actually installed the latest?
        }

        Context "When installing an already-installed runtime" {
            # Clear active KRE
            rundotnetsdk use none

            $runtimeName = GetRuntimeName "CLR" "x86"
            $runtimePath = "$env:USER_DOTNET_PATH\runtimes\$runtimeName"
            It "ensures the runtime is installed" {
                rundotnetsdk install $TestDotNetVersion -x86 -r "CLR"
                $dotnetsdkout[0] | Should Match "$runtimeName already installed"
                $runtimePath | Should Exist
            }
        }

        Context "When installing a specific nupkg" {
            $name = [IO.Path]::GetFileNameWithoutExtension($specificNupkgName)
            $runtimeRoot = "$env:USER_DOTNET_PATH\runtimes\$name"

            It "unpacks the runtime" {
                rundotnetsdk install $specificNupkgPath
            }
            
            It "installs the runtime into the user directory" {
                $runtimeRoot | Should Exist
            }

            It "did not assign an alias" {
                dir "$env:USER_DOTNET_PATH\alias\*.txt" | ForEach-Object {
                    $_ | Should Not Contain $name
                }
            }
        }
    }
    finally {
        # Clean the global directory
        del -rec -for $env:GLOBAL_DOTNET_PATH
    }
}