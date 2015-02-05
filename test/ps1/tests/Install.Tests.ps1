function DefineInstallTests($clr, $arch) {
    $runtimeHome = $UserPath
    $alias = "install_test_$arch_$clr"

    if($clr -eq "CoreCLR") {
        $fxName = "Asp.NetCore,Version=v5.0"
    } else {
        $fxName = "Asp.Net,Version=v5.0"
    }

    $runtimeName = GetRuntimeName $clr $arch
    $runtimeRoot = "$runtimeHome\runtimes\$runtimeName"

    Context "When installing $clr on $arch" {
        It "downloads and unpacks a runtime" {
            # Never crossgen in the automated tests since it takes a loooong time :(.
            __kvmtest_run install $TestRuntimeVersion -arch $arch -r $clr -a $alias -nonative | Out-Null
            $__kvmtest_exit | Should Be 0
        }

        It "installs the runtime into the user directory" {
            $runtimeRoot | Should Exist
        }

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
                "$runtimeRoot\bin\$RuntimeExecutableName" | Should Exist
                
                $output = & "$runtimeRoot\bin\$RuntimeExecutableName" run
                $LASTEXITCODE | Should Be 0
                $fullOutput = [String]::Join("`r`n", $output)
                $output | ForEach-Object { Write-Verbose $_ }

                $fullOutput | Should Match "Runtime is sane!"
                $fullOutput | Should Match "Runtime Framework:\s+$fxName"
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

Describe "install" -Tag "install" {
    DefineInstallTests "CLR" "x86"
    DefineInstallTests "CLR" "x64"
    DefineInstallTests "CoreCLR" "x86"
    DefineInstallTests "CoreCLR" "x64"

    Context "When installing a non-existant Runtime version" {
        __kvmtest_run install "0.0.1-thisisnotarealruntime" | Out-Null

        It "returns a non-zero exit code" {
            $__kvmtest_exit | Should Not Be 0
        }

        It "throws a 404 error" {
            $__kvmtest_err[0].Exception.Message | Should Be 'Exception calling "DownloadFile" with "2" argument(s): "The remote server returned an error: (404) Not Found."'
        }
    }

    Context "When no architecture is specified" {
        __kvmtest_run install $TestRuntimeVersion -r CLR | Out-Null
        $runtimeName = GetRuntimeName -clr CLR -arch x86

        It "uses x86" {
            $__kvmtest_out.Trim() | Should Be "'$runtimeName' is already installed."
        }
    }

    Context "When no clr is specified" {
        __kvmtest_run install $TestRuntimeVersion -arch x86 | Out-Null
        $runtimeName = GetRuntimeName -clr CLR -arch x86

        It "uses Desktop CLR" {
            $__kvmtest_out.Trim() | Should Be "'$runtimeName' is already installed."
        }
    }

    Context "When neither architecture nor clr is specified" {
        __kvmtest_run install $TestRuntimeVersion | Out-Null
        $runtimeName = GetRuntimeName -clr CLR -arch x86

        It "uses x86/Desktop" {
            $__kvmtest_out.Trim() | Should Be "'$runtimeName' is already installed."
        }
    }

    Context "When installing latest" {
        $previous = @(dir "$UserPath\runtimes" | select -ExpandProperty Name)
        It "downloads a runtime" {
            __kvmtest_run install latest -arch x86 -r CLR | Out-Null
        }
        # TODO: Check that it actually installed the latest?
    }

    Context "When installing an already-installed runtime" {
        # Clear active dotnet runtime
        __kvmtest_run use none | Out-Null

        $runtimeName = GetRuntimeName "CLR" "x86"
        $runtimePath = "$UserPath\runtimes\$runtimeName"
        It "ensures the runtime is installed" {
            __kvmtest_run install $TestRuntimeVersion -arch x86 -r "CLR" | Out-Null
            $__kvmtest_out.Trim() | Should Be "'$runtimeName' is already installed."
            $runtimePath | Should Exist
        }
    }

    Context "When installing a specific package" {
        $name = [IO.Path]::GetFileNameWithoutExtension($specificNupkgName)
        $runtimeRoot = "$UserPath\runtimes\$name"

        It "unpacks the runtime" {
            __kvmtest_run install $specificNupkgPath | Out-Null
        }

        It "installs the runtime into the user directory" {
            $runtimeRoot | Should Exist
        }
    }
}