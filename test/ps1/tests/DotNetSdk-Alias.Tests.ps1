# Ensure a Runtime has been installed (if the other tests ran first, we're good)
rundotnetsdk install $TestKreVersion -arch "x86" -r "CLR"

$notRealRuntimeVersion = "0.0.1-notarealruntime"

$kreName = GetRuntimeName "CLR" "x86"
$notRealKreName = GetRuntimeName "CLR" "x86" $notRealRuntimeVersion

$testAlias = "alias_test_" + [Guid]::NewGuid().ToString("N")
$testDefaultAlias = "alias_testDefault_" + [Guid]::NewGuid().ToString("N")
$notRealAlias = "alias_notReal_" + [Guid]::NewGuid().ToString("N")
$bogusAlias = "alias_bogus_" + [Guid]::NewGuid().ToString("N")

Describe "dotnetsdk-ps1 alias" -Tag "dotnetsdk-alias" {
    Context "When defining an alias for a Runtime that exists" {
        rundotnetsdk alias $testAlias $TestKreVersion -x86 -r CLR

        It "writes the alias file" {
            "$env:USER_DOTNET_PATH\alias\$testAlias.txt" | Should Exist
            "$env:USER_DOTNET_PATH\alias\$testAlias.txt" | Should ContainExactly $kreName
        }
    }

    Context "When defining an alias for a Runtime with no arch or clr parameters" {
        rundotnetsdk alias $testDefaultAlias $TestKreVersion

        It "writes the x86/CLR variant to the alias file" {
            "$env:USER_DOTNET_PATH\alias\$testDefaultAlias.txt" | Should Exist
            "$env:USER_DOTNET_PATH\alias\$testDefaultAlias.txt" | Should ContainExactly $kreName   
        }
    }

    Context "When defining an alias for a Runtime that does not exist" {
        rundotnetsdk alias $notRealAlias $notRealRuntimeVersion -x86 -r CLR

        It "writes the alias file" {
            "$env:USER_DOTNET_PATH\alias\$notRealAlias.txt" | Should Exist
            "$env:USER_DOTNET_PATH\alias\$notRealAlias.txt" | Should ContainExactly $notRealKreName   
        }
    }

    Context "When displaying an alias" {
        rundotnetsdk alias $testAlias
        It "outputs the value of the alias" {
            $dotnetsdkout[0] | Should Be "Alias '$testAlias' is set to $kreName"
        }
    }

    Context "When given an non-existant alias" {
        rundotnetsdk alias $bogusAlias

        It "outputs an error" {
            $dotnetsdkout[0] | Should Be "Alias '$bogusAlias' does not exist"
        }

        It "returns a non-zero exit code" {
            $dotnetsdkexit | Should Not Be 0
        }
    }

    Context "When displaying all aliases" {
        $allAliases = rundotnetsdk alias | Out-String

        It "lists all aliases in the alias files" {
            dir "$env:USER_DOTNET_PATH\alias\*.txt" | ForEach-Object {
                $alias = [Regex]::Escape([IO.Path]::GetFileNameWithoutExtension($_.Name))
                $val = [Regex]::Escape((Get-Content $_))

                # On some consoles, the value of the alias gets cut off, so don't require it in the assertion.
                $allAliases | Should Match ".*$alias.*"
            }
        }
    }
}

Describe "dotnetsdk-ps1 unalias" -Tag "dotnetsdk-alias" {
    Context "When removing an alias that does not exist" {
        rundotnetsdk unalias $bogusAlias

        It "outputs an error" {
            $dotnetsdkout[0] | Should Be "Cannot remove alias, '$bogusAlias' is not a valid alias name"
        }

        It "returns a non-zero exit code" {
            $dotnetsdkexit | Should Not Be 0
        }
    }

    Context "When removing an alias that does exist" {
        rundotnetsdk unalias $testAlias

        It "removes the alias file" {
            "$env:USER_DOTNET_PATH\alias\$testAlias.txt" | Should Not Exist
        }
    }
}