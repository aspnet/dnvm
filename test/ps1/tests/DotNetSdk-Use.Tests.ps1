# Ensure some KREs have been installed (if the other tests ran first, we're good)
rundotnetsdk install $TestDotNetVersion -arch "x86" -r "CLR"

$notRealRuntimeVersion = "0.0.1-notarealkre"

$runtimeName = GetRuntimeName "CLR" "x86"
$notRealRuntimeName = GetRuntimeName "CLR" "x86" $notRealRuntimeVersion

$testAlias = "use_test_" + [Guid]::NewGuid().ToString("N")
$notRealAlias = "use_notReal_" + [Guid]::NewGuid().ToString("N")
$bogusAlias = "use_bogus_" + [Guid]::NewGuid().ToString("N")

rundotnetsdk alias $testAlias $TestDotNetVersion -arch "x86" -r "CLR"
rundotnetsdk use none

Describe "dotnetsdk-ps1 use" -Tag "dotnetsdk-use" {
    Context "When use-ing without a clr or architecture" {
        rundotnetsdk use $TestDotNetVersion
        $runtimeName = GetRuntimeName -clr CLR -arch x86

        It "uses x86/CLR variant" {
            GetActiveRuntimeName | Should Be $runtimeName
        }

        rundotnetsdk use none
    }

    Context "When use-ing a runtime" {
        rundotnetsdk use $TestDotNetVersion
        $runtimeName = GetRuntimeName -clr CLR -arch x86

        # 'k.cmd' still exists, for now.
        It "puts K on the PATH" {
            $cmd = Get-Command k -ErrorAction SilentlyContinue
            $cmd | Should Not BeNullOrEmpty
            $cmd.Definition | Should Be (Convert-Path "$env:DOTNET_USER_PATH\runtimes\$runtimeName\bin\k.cmd")
        }

        It "puts kpm on the PATH" {
            $cmd = Get-Command kpm -ErrorAction SilentlyContinue
            $cmd | Should Not BeNullOrEmpty
            $cmd.Definition | Should Be (Convert-Path "$env:DOTNET_USER_PATH\runtimes\$runtimeName\bin\kpm.cmd")
        }

        It "puts dotnet on the PATH" {
            $cmd = Get-Command dotnet -ErrorAction SilentlyContinue
            $cmd | Should Not BeNullOrEmpty
            $cmd.Definition | Should Be (Convert-Path "$env:DOTNET_USER_PATH\runtimes\$runtimeName\bin\dotnet.exe")
        }

        rundotnetsdk use none
    }

    Context "When use-ing an alias" {
        rundotnetsdk use $testAlias

        # 'k.cmd' still exists, for now.
        It "puts K on the PATH" {
            $cmd = Get-Command k -ErrorAction SilentlyContinue
            $cmd | Should Not BeNullOrEmpty
            $cmd.Definition | Should Be (Convert-Path "$env:DOTNET_USER_PATH\runtimes\$runtimeName\bin\k.cmd")
        }

        It "puts kpm on the PATH" {
            $cmd = Get-Command kpm -ErrorAction SilentlyContinue
            $cmd | Should Not BeNullOrEmpty
            $cmd.Definition | Should Be (Convert-Path "$env:DOTNET_USER_PATH\runtimes\$runtimeName\bin\kpm.cmd")
        }

        It "puts dotnet on the PATH" {
            $cmd = Get-Command dotnet -ErrorAction SilentlyContinue
            $cmd | Should Not BeNullOrEmpty
            $cmd.Definition | Should Be (Convert-Path "$env:DOTNET_USER_PATH\runtimes\$runtimeName\bin\dotnet.exe")
        }
    }

    Context "When use-ing 'none'" {
        rundotnetsdk use $TestDotNetVersion

        rundotnetsdk use none

        It "removes the KRE from the PATH" {
            GetRuntimesOnPath | Should BeNullOrEmpty
        }

        It "removes K from the PATH" {
            $cmd = (Get-Command k -ErrorAction SilentlyContinue)
        }

        It "removes kpm from the PATH" {
            (Get-Command kpm -ErrorAction SilentlyContinue) | Should BeNullOrEmpty
        }

        It "removes dotnet from the PATH" {
            (Get-Command dotnet -ErrorAction SilentlyContinue) | Should BeNullOrEmpty
        }
    }

    Context "When use-ing a non-existant version" {
        It "should throw an error" {
            rundotnetsdk use $notRealRuntimeVersion
            $dotnetsdkerr[0].Exception.Message | Should Be "Cannot find $notRealRuntimeName, do you need to run 'dotnetsdk install $notRealRuntimeVersion'?"
        }
    }

    Context "When use-ing a non-existant alias" {
        It "should throw an error" {
            rundotnetsdk use "bogus_alias_that_does_not_exist"
            $dotnetsdkerr[0].Exception.Message | Should Be "Cannot find dotnet-clr-win-x86.bogus_alias_that_does_not_exist, do you need to run 'dotnetsdk install bogus_alias_that_does_not_exist'?"
        }
    }
}