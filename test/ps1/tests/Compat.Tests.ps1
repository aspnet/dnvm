Describe "compat" -Tag "compat" {
    Context "When -x86 is specified" {
        It "set architecture appropriately" {
            __dnvmtest_run name 1.0.0 -x86 | Should Be "dnx-clr-win-x86.1.0.0"
        }
    }
    Context "When -x64 is specified" {
        It "set architecture appropriately" {
            __dnvmtest_run name 1.0.0 -x64 | Should Be "dnx-clr-win-x64.1.0.0"
        }
    }
    Context "When -amd64 is specified" {
        It "set architecture appropriately" {
            __dnvmtest_run name 1.0.0 -amd64 | Should Be "dnx-clr-win-x64.1.0.0"
        }
    }
}
