# Ensure a Runtime has been installed (if the other tests ran first, we're good)
__dnvmtest_run install $TestRuntimeVersion -arch "x86" -r "CLR"

$notRealRuntimeVersion = "0.0.1-notarealruntime"

$runtimeName = GetRuntimeName "CLR" "x86"
$notRealRuntimeName = GetRuntimeName "CLR" "x86" $notRealRuntimeVersion

$testAlias = "alias_test_" + [Guid]::NewGuid().ToString("N")
$testDefaultAlias = "alias_testDefault_" + [Guid]::NewGuid().ToString("N")
$notRealAlias = "alias_notReal_" + [Guid]::NewGuid().ToString("N")
$bogusAlias = "alias_bogus_" + [Guid]::NewGuid().ToString("N")

Describe "alias" -Tag "alias" {
    Context "When defining an alias for a Runtime that exists" {
        __dnvmtest_run alias $testAlias $TestRuntimeVersion -x86 -r CLR | Out-Null

        It "writes the alias file" {
            "$UserPath\alias\$testAlias.txt" | Should Exist
            cat "$UserPath\alias\$testAlias.txt" | Should Be $runtimeName
        }
    }

    Context "When defining an alias for a Runtime with no arch or clr parameters" {
        __dnvmtest_run alias $testDefaultAlias $TestRuntimeVersion | Out-Null

        It "writes the x86/CLR variant to the alias file" {
            "$UserPath\alias\$testDefaultAlias.txt" | Should Exist
            cat "$UserPath\alias\$testDefaultAlias.txt" | Should Be $runtimeName
        }
    }

    Context "When defining an alias for a Runtime that does not exist" {
        __dnvmtest_run alias $notRealAlias $notRealRuntimeVersion -x86 -r CLR | Out-Null

        It "writes the alias file" {
            "$UserPath\alias\$notRealAlias.txt" | Should Exist
        }
    }

    Context "When displaying an alias" {
        __dnvmtest_run alias $testAlias | Out-Null
        It "outputs the value of the alias" {
            $__dnvmtest_out.Trim() | Should Be "Alias '$testAlias' is set to '$runtimeName'"
        }
    }
    
    Context "When aliasing a full package name" {
        __dnvmtest_run alias "alias_fullname_test" $runtimeName | Out-Null

        It "correctly writes the alias" {
            "$UserPath\alias\alias_fullname_test.txt" | Should Exist
            cat "$UserPath\alias\alias_fullname_test.txt" | Should Be $runtimeName
        }
    }

    Context "When given an non-existant alias" {
        __dnvmtest_run alias $bogusAlias | Out-Null

        It "outputs an error" {
            $__dnvmtest_out.Trim() | Should Be "Alias does not exist: '$bogusAlias'"
        }

        It "returns a non-zero exit code" {
            $__dnvmtest_exit | Should Not Be 0
        }
    }

    Context "When displaying all aliases" {
        $allAliases = __dnvmtest_run alias | Out-String

        It "lists all aliases in the alias files" {
            dir "$UserPath\alias\*.txt" | ForEach-Object {
                $alias = [Regex]::Escape([IO.Path]::GetFileNameWithoutExtension($_.Name))

                # On some consoles, the value of the alias gets cut off, so don't require it in the assertion.
                # Instead, we just test the short prefix
                $allAliases | Should Match ".*alias_.*"
            }
        }
    }

    Context "When removing an alias that does not exist" {
        __dnvmtest_run alias -d $bogusAlias | Out-Null

        It "outputs an error" {
            $__dnvmtest_out.Trim() | Should Be "Cannot remove alias '$bogusAlias'. It does not exist."
        }

        It "returns a non-zero exit code" {
            $__dnvmtest_exit | Should Not Be 0
        }
    }

    Context "When removing an alias that does exist" {
        __dnvmtest_run alias -d $testAlias | Out-Null

        It "removes the alias file" {
            "$UserPath\alias\$testAlias.txt" | Should Not Exist
        }
    }
}
