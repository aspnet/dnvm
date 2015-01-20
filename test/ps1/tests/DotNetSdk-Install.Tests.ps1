function DefineInstallTests($clr, $arch) {
    $runtimeHome = $env:DOTNET_USER_PATH
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
            rundotnetsdk install $TestDotNetVersion -arch $arch -r $clr -a $alias -nonative
            $dotnetsdkexit | Should Be 0
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
                $output = & "$runtimeRoot\bin\$RuntimeExecutableName" run
                $LASTEXITCODE | Should Be 0
                $fullOutput = [String]::Join("`r`n", $output)
                $output | ForEach-Object { Write-Verbose "dotnet: $_" }

                $fullOutput | Should Match "Runtime is sane!"
                $fullOutput | Should Match "Runtime Framework:\s+$fxName"
            } finally {
                popd
            }
        }

        It "assigned the requested alias" {
            "$env:DOTNET_USER_PATH\alias\$alias.txt" | Should Exist
            "$env:DOTNET_USER_PATH\alias\$alias.txt" | Should ContainExactly $runtimeName
        }

        It "uses the new Runtime" {
            GetActiveRuntimeName $runtimeHome | Should Be "$runtimeName"
        }
    }
}

Describe "dotnetsdk-ps1 install" -Tag "dotnetsdk-install" {
    DefineInstallTests "CLR" "x86"
    DefineInstallTests "CLR" "x64"
    DefineInstallTests "CoreCLR" "x86"
    DefineInstallTests "CoreCLR" "x64"

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
        $previous = @(dir "$env:DOTNET_USER_PATH\runtimes" | select -ExpandProperty Name)
        It "downloads a runtime" {
            rundotnetsdk install latest -arch x86 -r CLR
        }
        # TODO: Check that it actually installed the latest?
    }

    Context "When installing an already-installed runtime" {
        # Clear active dotnet runtime
        rundotnetsdk use none

        $runtimeName = GetRuntimeName "CLR" "x86"
        $runtimePath = "$env:DOTNET_USER_PATH\runtimes\$runtimeName"
        It "ensures the runtime is installed" {
            rundotnetsdk install $TestDotNetVersion -x86 -r "CLR"
            $dotnetsdkout[0] | Should Match "$runtimeName already installed"
            $runtimePath | Should Exist
        }
    }

    Context "When installing a specific nupkg" {
        $name = [IO.Path]::GetFileNameWithoutExtension($specificNupkgName)
        $runtimeRoot = "$env:DOTNET_USER_PATH\runtimes\$name"

        It "unpacks the runtime" {
            rundotnetsdk install $specificNupkgPath
        }

        It "installs the runtime into the user directory" {
            $runtimeRoot | Should Exist
        }
    }
}