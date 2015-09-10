Describe "run" -Tag "run" {
    __dnvmtest_run install $TestRuntimeVersion -r CLR | Out-Null

    Context "When a version is provided" {
        It "executes dnx with provides args" {
            __dnvmtest_run use none | Out-Null
            { Get-Command dnx -ErrorAction Stop } | Should Throw
            (__dnvmtest_run run $TestRuntimeVersion | Select-String -SimpleMatch "Microsoft .NET Execution environment CLR-x86-$TestRuntimeVersion") | Should Be $true
            $__dnvmtest_exit | Should Be 2
        }
    }

    Context "When an alias is provided" {
        It "executes dnx with provides args" {
            __dnvmtest_run alias "test_alias_run" $TestRuntimeVersion | Out-Null
            __dnvmtest_run use none | Out-Null
            { Get-Command dnx -ErrorAction Stop } | Should Throw
            (__dnvmtest_run run "test_alias_run" | Select-String -SimpleMatch "Microsoft .NET Execution environment CLR-x86-$TestRuntimeVersion") | Should Be $true
            $__dnvmtest_exit | Should Be 2
        }
    }
}

Describe "exec" -Tag "exec" {
    __dnvmtest_run install $TestRuntimeVersion -r CLR | Out-Null
    $runtimeName = GetRuntimeName "CLR" "x86"
    $runtimePath = "$UserPath\runtimes\$runtimeName"

    Context "When a version is provided" {
        It "executes the command with the expected dnx in path" {
            __dnvmtest_run use none | Out-Null
            { Get-Command dnx -ErrorAction Stop } | Should Throw
            (__dnvmtest_run exec $TestRuntimeVersion Get-Command dnx).Definition | Should Be "$runtimePath\bin\dnx.exe"
        }
    }

    Context "When an alias is provided" {
        It "executes the command with the expected dnx in path" {
            __dnvmtest_run alias "test_alias_exec" $TestRuntimeVersion
            __dnvmtest_run use none | Out-Null
            { Get-Command dnx -ErrorAction Stop } | Should Throw
            (__dnvmtest_run exec test_alias_exec Get-Command dnx).Definition | Should Be "$runtimePath\bin\dnx.exe"
        }
    }
}
