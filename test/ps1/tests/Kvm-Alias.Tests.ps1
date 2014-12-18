# Ensure a KRE has been installed (if the other tests ran first, we're good)
runkvm install $TestKreVersion -arch "x86" -r "CLR"

$notRealKreVersion = "0.0.1-notarealkre"

$kreName = GetKreName "CLR" "x86"
$notRealKreName = GetKreName "CLR" "x86" $notRealKreVersion

$testAlias = "alias_test_" + [Guid]::NewGuid().ToString("N")
$testDefaultAlias = "alias_testDefault_" + [Guid]::NewGuid().ToString("N")
$notRealAlias = "alias_notReal_" + [Guid]::NewGuid().ToString("N")
$bogusAlias = "alias_bogus_" + [Guid]::NewGuid().ToString("N")

Describe "kvm-ps1 alias" -Tag "kvm-alias" {
    Context "When defining an alias for a KRE that exists" {
        runkvm alias $testAlias $TestKreVersion -x86 -r CLR
        
        It "writes the alias file" {
            "$env:USER_KRE_PATH\alias\$testAlias.txt" | Should Exist
            "$env:USER_KRE_PATH\alias\$testAlias.txt" | Should ContainExactly $kreName
        }
    }

    Context "When defining an alias for a KRE with no arch or clr parameters" {
        runkvm alias $testDefaultAlias $TestKreVersion

        It "writes the x86/CLR variant to the alias file" {
            "$env:USER_KRE_PATH\alias\$testDefaultAlias.txt" | Should Exist
            "$env:USER_KRE_PATH\alias\$testDefaultAlias.txt" | Should ContainExactly $kreName   
        }
    }

    Context "When defining an alias for a KRE that does not exist" {
        runkvm alias $notRealAlias $notRealKreVersion -x86 -r CLR
        
        It "writes the alias file" {
            "$env:USER_KRE_PATH\alias\$notRealAlias.txt" | Should Exist
            "$env:USER_KRE_PATH\alias\$notRealAlias.txt" | Should ContainExactly $notRealKreName   
        }
    }

    Context "When displaying an alias" {
        runkvm alias $testAlias
        It "outputs the value of the alias" {
            $kvmout[0] | Should Be "Alias '$testAlias' is set to $kreName"
        }
    }

    Context "When given an non-existant alias" {
        runkvm alias $bogusAlias
        
        It "outputs an error" {
            $kvmout[0] | Should Be "Alias '$bogusAlias' does not exist"
        }

        It "returns a non-zero exit code" {
            $kvmexit | Should Not Be 0
        }
    }

    Context "When displaying all aliases" {
        $allAliases = runkvm alias | Out-String
        
        It "lists all aliases in the alias files" {
            dir "$env:USER_KRE_PATH\alias\*.txt" | ForEach-Object {
                $alias = [Regex]::Escape([IO.Path]::GetFileNameWithoutExtension($_.Name))
                $val = [Regex]::Escape((Get-Content $_))

                # On some consoles, the value of the alias gets cut off, so don't require it in the assertion.
                $allAliases | Should Match ".*$alias.*"
            }
        }
    }
}

Describe "kvm-ps1 unalias" -Tag "kvm-alias" {
    Context "When removing an alias that does not exist" {
        runkvm unalias $bogusAlias

        It "outputs an error" {
            $kvmout[0] | Should Be "Cannot remove alias, '$bogusAlias' is not a valid alias name"
        }

        It "returns a non-zero exit code" {
            $kvmexit | Should Not Be 0
        }
    }

    Context "When removing an alias that does exist" {
        runkvm unalias $testAlias

        It "removes the alias file" {
            "$env:USER_KRE_PATH\alias\$testAlias.txt" | Should Not Exist
        }
    }
}