# Ensure some KREs have been installed (if the other tests ran first, we're good)
__dnvmtest_run install $TestRuntimeVersion -arch "x86" -r "CLR"
__dnvmtest_run install $TestRuntimeVersion -arch "x64" -r "CoreCLR"

$notRealRuntimeVersion = "0.0.1-notarealruntime"

$runtimeName = GetRuntimeName "CLR" "x86"
$notRealRuntimeName = GetRuntimeName "CLR" "x86" $notRealRuntimeVersion

$testAlias = "use_test_" + [Guid]::NewGuid().ToString("N")
$notRealAlias = "use_notReal_" + [Guid]::NewGuid().ToString("N")
$bogusAlias = "use_bogus_" + [Guid]::NewGuid().ToString("N")

__dnvmtest_run alias $testAlias $TestRuntimeVersion -arch "x86" -r "CLR" | Out-Null
__dnvmtest_run use none | Out-Null

Describe "use" -Tag "use" {
    Context "When use-ing without a clr or architecture" {
        __dnvmtest_run use $TestRuntimeVersion | Out-Null
        $runtimeName = GetRuntimeName -clr CLR -arch x86

        It "uses x86/CLR variant" {
            GetActiveRuntimeName | Should Be $runtimeName
        }

        __dnvmtest_run use none | Out-Null
    }

    Context "When use-ing a runtime" {
        __dnvmtest_run use $TestRuntimeVersion | Out-Null
        $runtimeName = GetRuntimeName -clr CLR -arch x86

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

        __dnvmtest_run use none | Out-Null
    }

    Context "When use-ing an alias" {
        __dnvmtest_run use $testAlias | Out-Null

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
    
    Context "When use-ing an ailas, overriding -arch and -r" {
        __dnvmtest_run use $testAlias -arch "x64" -r "CoreCLR" | Out-Null
        $runtimeName = GetRuntimeName -clr CoreCLR -arch x64

        It "uses x64/CoreCLR variant" {
            GetActiveRuntimeName | Should Be $runtimeName
        }

        __dnvmtest_run use none | Out-Null
    }

    Context "When use-ing 'none'" {
        __dnvmtest_run use $TestRuntimeVersion | Out-Null

        __dnvmtest_run use none | Out-Null

        It "removes the Runtime from the PATH" {
            GetRuntimesOnPath | Should BeNullOrEmpty
        }

        It "removes $PackageManagerName from the PATH" {
            (Get-Command $PackageManagerName -ErrorAction SilentlyContinue) | Should BeNullOrEmpty
        }

        It "removes $RuntimeHostName from the PATH" {
            (Get-Command $RuntimeHostName -ErrorAction SilentlyContinue) | Should BeNullOrEmpty
        }
    }
}
