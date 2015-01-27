# Ensure a Runtime has been installed (if the other tests ran first, we're good)
__kvmtest_run install $TestRuntimeVersion -arch "x86" -r "CLR"

$notRealRuntimeVersion = "0.0.1-notarealruntime"

$runtimeName = GetRuntimeName "CLR" "x86"
$notRealKreName = GetRuntimeName "CLR" "x86" $notRealRuntimeVersion

$testAlias = "alias_test_" + [Guid]::NewGuid().ToString("N")
$testDefaultAlias = "alias_testDefault_" + [Guid]::NewGuid().ToString("N")
$notRealAlias = "alias_notReal_" + [Guid]::NewGuid().ToString("N")
$bogusAlias = "alias_bogus_" + [Guid]::NewGuid().ToString("N")

Describe "alias" -Tag "alias" {
    Context "When defining an alias for a Runtime that exists" {
        __kvmtest_run alias $testAlias $TestRuntimeVersion -x86 -r CLR

        It "writes the alias file" {
            "$UserPath\alias\$testAlias.txt" | Should Exist
            "$UserPath\alias\$testAlias.txt" | Should ContainExactly $runtimeName
        }
    }

    Context "When defining an alias for a Runtime with no arch or clr parameters" {
        __kvmtest_run alias $testDefaultAlias $TestRuntimeVersion

        It "writes the x86/CLR variant to the alias file" {
            "$UserPath\alias\$testDefaultAlias.txt" | Should Exist
            "$UserPath\alias\$testDefaultAlias.txt" | Should ContainExactly $runtimeName
        }
    }

    Context "When defining an alias for a Runtime that does not exist" {
        __kvmtest_run alias $notRealAlias $notRealRuntimeVersion -x86 -r CLR

        It "writes the alias file" {
            "$UserPath\alias\$notRealAlias.txt" | Should Exist
        }
    }

    Context "When displaying an alias" {
        __kvmtest_run alias $testAlias
        It "outputs the value of the alias" {
            $__kvmtest_out[0] | Should Be "Alias '$testAlias' is set to $runtimeName"
        }
    }

    Context "When given an non-existant alias" {
        __kvmtest_run alias $bogusAlias

        It "outputs an error" {
            $__kvmtest_out[0] | Should Be "Alias '$bogusAlias' does not exist"
        }

        It "returns a non-zero exit code" {
            $__kvmtest_exit | Should Not Be 0
        }
    }

    Context "When displaying all aliases" {
        $allAliases = __kvmtest_run alias | Out-String

        It "lists all aliases in the alias files" {
            dir "$UserPath\alias\*.txt" | ForEach-Object {
                $alias = [Regex]::Escape([IO.Path]::GetFileNameWithoutExtension($_.Name))
                $val = [Regex]::Escape((Get-Content $_))

                # On some consoles, the value of the alias gets cut off, so don't require it in the assertion.
                $allAliases | Should Match ".*$alias.*"
            }
        }
    }
}

Describe "unalias" -Tag "alias" {
    Context "When removing an alias that does not exist" {
        __kvmtest_run unalias $bogusAlias

        It "outputs an error" {
            $__kvmtest_out[0] | Should Be "Cannot remove alias, '$bogusAlias' is not a valid alias name"
        }

        It "returns a non-zero exit code" {
            $__kvmtest_exit | Should Not Be 0
        }
    }

    Context "When removing an alias that does exist" {
        __kvmtest_run unalias $testAlias

        It "removes the alias file" {
            "$UserPath\alias\$testAlias.txt" | Should Not Exist
        }
    }
}