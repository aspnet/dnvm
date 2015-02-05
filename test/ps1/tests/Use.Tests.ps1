# Ensure some KREs have been installed (if the other tests ran first, we're good)
__kvmtest_run install $TestRuntimeVersion -arch "x86" -r "CLR"

$notRealRuntimeVersion = "0.0.1-notarealruntime"

$runtimeName = GetRuntimeName "CLR" "x86"
$notRealRuntimeName = GetRuntimeName "CLR" "x86" $notRealRuntimeVersion

$testAlias = "use_test_" + [Guid]::NewGuid().ToString("N")
$notRealAlias = "use_notReal_" + [Guid]::NewGuid().ToString("N")
$bogusAlias = "use_bogus_" + [Guid]::NewGuid().ToString("N")

__kvmtest_run alias $testAlias $TestRuntimeVersion -arch "x86" -r "CLR" | Out-Null
__kvmtest_run use none | Out-Null

Describe "use" -Tag "use" {
    Context "When use-ing without a clr or architecture" {
        __kvmtest_run use $TestRuntimeVersion | Out-Null
        $runtimeName = GetRuntimeName -clr CLR -arch x86

        It "uses x86/CLR variant" {
            GetActiveRuntimeName | Should Be $runtimeName
        }

        __kvmtest_run use none | Out-Null
    }

    Context "When use-ing a runtime" {
        __kvmtest_run use $TestRuntimeVersion | Out-Null
        $runtimeName = GetRuntimeName -clr CLR -arch x86

        It "puts $RuntimeExecutableName on the PATH" {
            $cmd = Get-Command $RuntimeExecutableName -ErrorAction SilentlyContinue
            $cmd | Should Not BeNullOrEmpty
            $cmd.Definition | Should Be (Convert-Path "$UserPath\runtimes\$runtimeName\bin\$RuntimeExecutableName")
        }

        It "puts $PackageManagerName on the PATH" {
            $cmd = Get-Command $PackageManagerName -ErrorAction SilentlyContinue
            $cmd | Should Not BeNullOrEmpty
            $cmd.Definition | Should Be (Convert-Path "$UserPath\runtimes\$runtimeName\bin\$PackageManagerName")
        }

        It "puts $RuntimeHostName on the PATH" {
            $cmd = Get-Command $RuntimeHostName -ErrorAction SilentlyContinue
            $cmd | Should Not BeNullOrEmpty
            $cmd.Definition | Should Be (Convert-Path "$UserPath\runtimes\$runtimeName\bin\$RuntimeHostName")
        }

        __kvmtest_run use none | Out-Null
    }

    Context "When use-ing an alias" {
        __kvmtest_run use $testAlias | Out-Null

        # 'k.cmd' still exists, for now.
        It "puts $RuntimeExecutableName on the PATH" {
            $cmd = Get-Command $RuntimeExecutableName -ErrorAction SilentlyContinue
            $cmd | Should Not BeNullOrEmpty
            $cmd.Definition | Should Be (Convert-Path "$UserPath\runtimes\$runtimeName\bin\$RuntimeExecutableName")
        }

        It "puts $PackageManagerName on the PATH" {
            $cmd = Get-Command $PackageManagerName -ErrorAction SilentlyContinue
            $cmd | Should Not BeNullOrEmpty
            $cmd.Definition | Should Be (Convert-Path "$UserPath\runtimes\$runtimeName\bin\$PackageManagerName")
        }

        It "puts $RuntimeHostName on the PATH" {
            $cmd = Get-Command $RuntimeHostName -ErrorAction SilentlyContinue
            $cmd | Should Not BeNullOrEmpty
            $cmd.Definition | Should Be (Convert-Path "$UserPath\runtimes\$runtimeName\bin\$RuntimeHostName")
        }
    }

    Context "When use-ing 'none'" {
        __kvmtest_run use $TestRuntimeVersion | Out-Null

        __kvmtest_run use none | Out-Null

        It "removes the Runtime from the PATH" {
            GetRuntimesOnPath | Should BeNullOrEmpty
        }

        It "removes $RuntimeExecutableName from the PATH" {
            $cmd = (Get-Command $RuntimeExecutableName -ErrorAction SilentlyContinue)
        }

        It "removes $PackageManagerName from the PATH" {
            (Get-Command $PackageManagerName -ErrorAction SilentlyContinue) | Should BeNullOrEmpty
        }

        It "removes $RuntimeHostName from the PATH" {
            (Get-Command $RuntimeHostName -ErrorAction SilentlyContinue) | Should BeNullOrEmpty
        }
    }

    Context "When use-ing a non-existant version" {
        It "should throw an error" {
            __kvmtest_run use $notRealRuntimeVersion | Out-Null
            $__kvmtest_err[0].Exception.Message | Should Be "Cannot find $notRealRuntimeName, do you need to run '$CommandName install $notRealRuntimeVersion'?"
        }
    }

    Context "When use-ing a non-existant alias" {
        It "should throw an error" {
            __kvmtest_run use "bogus_alias_that_does_not_exist" | Out-Null
            $__kvmtest_err[0].Exception.Message | Should Be "Cannot find $RuntimePackageName-clr-win-x86.bogus_alias_that_does_not_exist, do you need to run '$CommandName install bogus_alias_that_does_not_exist'?"
        }
    }
}