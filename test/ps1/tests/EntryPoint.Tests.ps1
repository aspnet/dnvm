Describe "entrypoint" -Tag "entrypoint" {
    Context "When an invalid command is specified" {
        It "returns exit code and displays help" {
            __kvmtest_run sdfjklsdfljkasdfjklasdfjkl | Out-Null
            $__kvmtest_exit | Should Be 1002
            $__kvmtest_out | Should Match "usage:"
        }
    }
    Context "When no arguments are provided" {
        It "returns exit code and displays help" {
            __kvmtest_run | Out-Null
            $__kvmtest_exit | Should Be 1003
            $__kvmtest_out | Should Match "usage:"
        }
    }
}