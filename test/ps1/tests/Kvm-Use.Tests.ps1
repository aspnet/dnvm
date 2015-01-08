# Ensure some KREs have been installed (if the other tests ran first, we're good)
runkvm install $TestKreVersion -arch "x86" -r "CLR"

$notRealKreVersion = "0.0.1-notarealkre"

$kreName = GetKreName "CLR" "x86"
$notRealKreName = GetKreName "CLR" "x86" $notRealKreVersion

$testAlias = "use_test_" + [Guid]::NewGuid().ToString("N")
$notRealAlias = "use_notReal_" + [Guid]::NewGuid().ToString("N")
$bogusAlias = "use_bogus_" + [Guid]::NewGuid().ToString("N")

runkvm alias $testAlias $TestKreVersion -arch "x86" -r "CLR"
runkvm use none
        
Describe "kvm-ps1 use" -Tag "kvm-use" {
    Context "When use-ing without a runtime or architecture" {
        runkvm use $TestKreVersion
        $kreName = GetKreName -clr CLR -arch x86

        It "uses x86/CLR variant" {
            GetActiveKreName | Should Be $kreName
        }

        runkvm use none
    }

    Context "When use-ing a KRE" {
        runkvm use $TestKreVersion
        $kreName = GetKreName -clr CLR -arch x86

        It "puts K on the PATH" {
            $cmd = Get-Command k -ErrorAction SilentlyContinue
            $cmd | Should Not BeNullOrEmpty
            $cmd.Definition | Should Be (Convert-Path "$env:USER_KRE_PATH\packages\$kreName\bin\k.cmd")
        }

        It "puts kpm on the PATH" {
            $cmd = Get-Command kpm -ErrorAction SilentlyContinue
            $cmd | Should Not BeNullOrEmpty
            $cmd.Definition | Should Be (Convert-Path "$env:USER_KRE_PATH\packages\$kreName\bin\kpm.cmd")
        }

        It "puts klr on the PATH" {
            $cmd = Get-Command klr -ErrorAction SilentlyContinue
            $cmd | Should Not BeNullOrEmpty
            $cmd.Definition | Should Be (Convert-Path "$env:USER_KRE_PATH\packages\$kreName\bin\klr.exe")
        }

        runkvm use none
    }

    Context "When use-ing an alias" {
        # Sanity check assumptions
        Get-Command k -ErrorAction SilentlyContinue | Should BeNullOrEmpty

        runkvm use $testAlias

        It "puts K on the PATH" {
            $cmd = Get-Command k -ErrorAction SilentlyContinue
            $cmd | Should Not BeNullOrEmpty
            $cmd.Definition | Should Be (Convert-Path "$env:USER_KRE_PATH\packages\$kreName\bin\k.cmd")
        }

        It "puts kpm on the PATH" {
            $cmd = Get-Command kpm -ErrorAction SilentlyContinue
            $cmd | Should Not BeNullOrEmpty
            $cmd.Definition | Should Be (Convert-Path "$env:USER_KRE_PATH\packages\$kreName\bin\kpm.cmd")
        }

        It "puts klr on the PATH" {
            $cmd = Get-Command klr -ErrorAction SilentlyContinue
            $cmd | Should Not BeNullOrEmpty
            $cmd.Definition | Should Be (Convert-Path "$env:USER_KRE_PATH\packages\$kreName\bin\klr.exe")
        }
    }

    Context "When use-ing 'none'" {
        runkvm use $TestKreVersion
        
        runkvm use none

        It "removes the KRE from the PATH" {
            GetKresOnPath | Should BeNullOrEmpty
        }

        It "removes K from the PATH" {
            (Get-Command k -ErrorAction SilentlyContinue) | Should BeNullOrEmpty
        }

        It "removes kpm from the PATH" {
            (Get-Command kpm -ErrorAction SilentlyContinue) | Should BeNullOrEmpty
        }

        It "removes klr from the PATH" {
            (Get-Command klr -ErrorAction SilentlyContinue) | Should BeNullOrEmpty
        }
    }

    Context "When use-ing a non-existant version" {
        It "should throw an error" {
            runkvm use $notRealKreVersion
            $kvmerr[0].Exception.Message | Should Be "Cannot find $notRealKreName, do you need to run 'kvm install $notRealKreVersion'?"
        }
    }

    Context "When use-ing a non-existant alias" {
        It "should throw an error" {
            runkvm use "bogus_alias_that_does_not_exist"
            $kvmerr[0].Exception.Message | Should Be "Cannot find KRE-CLR-x86.bogus_alias_that_does_not_exist, do you need to run 'kvm install bogus_alias_that_does_not_exist'?"
        }
    }
}