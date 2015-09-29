function DefineInstallTests($clr, $arch, $os) {
    $runtimeHome = $UserPath
    $alias = "install_test_$arch_$clr"

    if($clr -eq "CoreCLR") {
        $fxName = "Asp.NetCore,Version=v5.0"
    } else {
        $fxName = "Asp.Net,Version=v5.0"
    }

    $runtimeName = GetRuntimeName $clr $arch -OS:$os
    $runtimeRoot = "$runtimeHome\runtimes\$runtimeName"

    Context "When installing $clr on $arch for $os" {
        It "downloads and unpacks a runtime" {
            # Never crossgen in the automated tests since it takes a loooong time :(.
            if($clr -eq "mono") {
                __dnvmtest_run install $TestRuntimeVersion -arch $arch -r $clr -os $os -nonative | Out-Null
            } else {
                __dnvmtest_run install $TestRuntimeVersion -arch $arch -r $clr -alias $alias -os $os -nonative | Out-Null
            }
            $__dnvmtest_exit | Should Be 0
        }

        It "installs the runtime into the user directory" {
            $runtimeRoot | Should Exist
        }

        #We want to verify that non windows runtimes install, but they will not be able to restore or run an app.
        if($os -eq "win") {
            It "can restore packages for the TestApp sample" {
                pushd "$TestAppsDir\TestApp"
                try {
                    & "$runtimeRoot\bin\$PackageManagerName" restore
                } finally {
                    popd
                }
            }

            It "can run the TestApp sample" {
                pushd "$TestAppsDir\TestApp"
                try {
                    "$runtimeRoot\bin\$RuntimeHostName" | Should Exist
                    
                    $output = & "$runtimeRoot\bin\$RuntimeHostName" run
                    $LASTEXITCODE | Should Be 0
                    $fullOutput = [String]::Join("`r`n", $output)
                    $output | ForEach-Object { Write-Verbose $_ }
    
                    $fullOutput | Should Match "Runtime is sane!"
                } finally {
                    popd
                }
            }

            It "assigned the requested alias" {
                "$UserPath\alias\$alias.txt" | Should Exist
                "$UserPath\alias\$alias.txt" | Should ContainExactly $runtimeName
            }
    
            It "uses the new Runtime" {
                GetActiveRuntimeName $runtimeHome | Should Be "$runtimeName"
            }
        }
    }
}

Describe "install" -Tag "install" {
    DefineInstallTests "CLR" "x86" "win"
    DefineInstallTests "CLR" "x64" "win"
    DefineInstallTests "CoreCLR" "x86" "win"
    DefineInstallTests "CoreCLR" "x64" "win"
    DefineInstallTests "CoreCLR" "x64" "linux"
    DefineInstallTests "CoreCLR" "x64" "darwin"
    DefineInstallTests "Mono" "x86" "linux"

    Context "When installing a non-existant Runtime version" {
        __dnvmtest_run install "0.0.1-thisisnotarealruntime" | Out-Null

        It "returns a non-zero exit code" {
            $__dnvmtest_exit | Should Not Be 0
        }
    }

    Context "When no architecture is specified" {
        __dnvmtest_run install $TestRuntimeVersion -r CLR | Out-Null
        $runtimeName = GetRuntimeName -clr CLR -arch x86

        It "uses x86" {
            ($__dnvmtest_out.Trim() -like "*'$runtimeName' is already installed in $UserPath\runtimes\$runtimeName.`r`nAdding $UserPath\runtimes\$runtimeName\bin to process PATH*") | Should Be $true
        }
    }

    Context "When no clr is specified" {
        __dnvmtest_run install $TestRuntimeVersion -arch x86 | Out-Null
        $runtimeName = GetRuntimeName -clr CLR -arch x86

        It "uses Desktop CLR" {
             ($__dnvmtest_out.Trim() -like "*'$runtimeName' is already installed in $UserPath\runtimes\$runtimeName.`r`nAdding $UserPath\runtimes\$runtimeName\bin to process PATH*") | Should Be $true 
        }
    }

    Context "When neither architecture nor clr is specified" {
        __dnvmtest_run install $TestRuntimeVersion | Out-Null
        $runtimeName = GetRuntimeName -clr CLR -arch x86

        It "uses x86/Desktop" {
            ($__dnvmtest_out.Trim() -like "*'$runtimeName' is already installed in $UserPath\runtimes\$runtimeName.`r`nAdding $UserPath\runtimes\$runtimeName\bin to process PATH*") | Should Be $true
        }
    }

    Context "When installing an alias" {
        __dnvmtest_run install $TestRuntimeVersion -Alias "test_install_alias" | Out-Null
        $runtimeName = GetRuntimeName "CoreCLR" "x86"
        $runtimePath = "$UserPath\runtimes\$runtimeName"
        if(Test-Path $runtimePath) { del -rec -for $runtimePath }
        $runtimePath | Should Not Exist
        
        It "downloads the same version but with the specified runtime" {
            __dnvmtest_run install "test_install_alias" -r coreclr -nonative | Out-Null
            $runtimePath | Should Exist
        }
    }

    Context "When installing latest" {
        $previous = @(dir "$UserPath\runtimes" | select -ExpandProperty Name)
        It "downloads a runtime" {
            __dnvmtest_run install latest -arch x86 -r CLR | Out-Null
        }
        # TODO: Check that it actually installed the latest?
    }

    Context "When installing latest linux package" {
        $previous = @(dir "$UserPath\runtimes" | select -ExpandProperty Name)
        It "downloads a runtime" {
            __dnvmtest_run install latest -arch x86 -r mono -OS Linux | Out-Null
        }
        
        It "returns a zero exit code" {
            $__dnvmtest_exit | Should Be 0
        }
    }

    Context "When installing latest darwin package" {
        $previous = @(dir "$UserPath\runtimes" | select -ExpandProperty Name)
        It "downloads a runtime" {
            __dnvmtest_run install latest -arch x86 -r mono -OS Darwin | Out-Null
        }
        
        It "returns a zero exit code" {
            $__dnvmtest_exit | Should Be 0
        }
    }

    Context "When installing latest darwin coreclr" {
        $previous = @(dir "$UserPath\runtimes" | select -ExpandProperty Name)
        It "downloads a runtime" {
            __dnvmtest_run install latest -arch x64 -r CoreCLR -OS Darwin | Out-Null
        }
        
        It "returns a zero exit code" {
            $__dnvmtest_exit | Should Be 0
        }
    }

    Context "When installing an already-installed runtime" {
        # Clear active runtime
        __dnvmtest_run use none | Out-Null

        $runtimeName = GetRuntimeName "CLR" "x86"
        $runtimePath = "$UserPath\runtimes\$runtimeName"
        It "ensures the runtime is installed" {
            __dnvmtest_run install $TestRuntimeVersion -arch x86 -r "CLR" | Out-Null
            ($__dnvmtest_out.Trim() -like "*'$runtimeName' is already installed in $UserPath\runtimes\$runtimeName.`r`nAdding $UserPath\runtimes\$runtimeName\bin to process PATH*") | Should Be $true
            $runtimePath | Should Exist
        }
    }

    Context "When installing a specific package" {
        $name = [IO.Path]::GetFileNameWithoutExtension($specificNupkgName)
        $runtimeRoot = "$UserPath\runtimes\$name"

        It "unpacks the runtime" {
            __dnvmtest_run install $specificNupkgPath | Out-Null
        }

        It "installs the runtime into the user directory" {
            $runtimeRoot | Should Exist
        }
    }

    Context "When installing global" {
        $runtimeName = GetRuntimeName "CLR" "x86"
        if(Test-Path $UserPath\runtimes\$runtimeName) { del -rec -for $UserPath\runtimes\$runtimeName }
        if(Test-Path $GlobalPath\runtimes\$runtimeName) { del -rec -for $GlobalPath\runtimes\$runtimeName }

        It "installs runtime to global install location" {
            __dnvmtest_run install $TestRuntimeVersion -arch x86 -r "CLR" -g | Out-Null

            ($__dnvmtest_out.Trim() -like "*Installing to $GlobalPath\runtimes\$runtimeName`r`nAdding $GlobalPath\runtimes\$runtimeName\bin to process PATH*") | Should Be $true
            "$GlobalPath\runtimes\$runtimeName" | Should Exist
        }

        del -rec -for $GlobalPath\runtimes\$runtimeName
    }
}
