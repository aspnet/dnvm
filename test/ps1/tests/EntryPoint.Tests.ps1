Describe "entrypoint" -Tag "entrypoint" {
    __dnvmtest_run install $TestRuntimeVersion | Out-Null

    Context "When an invalid command is specified" {
        It "returns exit code and displays help" {
            __dnvmtest_run sdfjklsdfljkasdfjklasdfjkl | Out-Null
            $__dnvmtest_exit | Should Be 1002
            $__dnvmtest_out | Should Match "usage:"
        }
    }
    Context "When no arguments are provided" {
        It "returns exit code and displays help" {
            __dnvmtest_run | Out-Null
            $__dnvmtest_exit | Should Be 1003
            $__dnvmtest_out | Should Match "usage:"
        }
    }

    del -rec -for $UserPath\runtimes\
}
