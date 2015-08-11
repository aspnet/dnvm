# Ensure a Runtime has been installed (if the other tests ran first, we're good)
__dnvmtest_run install $TestRuntimeVersion -arch "x86" -r "CLR"

$foobarRuntime = "foo"
$foobarOS = "bar"
$foobarVersion = "1.0.0-beta7"
$foobarAlias = "foobar"
$foobarAliasRuntime = "$foobarRuntime-$foobarOS.$foobarVersion"

# Clean aliases (if exist) and create a orphaned alias and a default alias
if(Test-Path $UserPath\alias) {
    Get-ChildItem $UserPath\alias | ForEach-Object { Remove-Item $_.FullName }
}
else
{
    New-Item -ItemType directory -Path $UserPath\alias
}
New-Item -Force -Path $($UserPath + "\alias\" + $foobarAlias + ".txt") -Value $foobarAliasRuntime -ItemType File
New-Item -Force -Path $($UserPath + "\alias\default.txt") -Value $("dnx-clr-win-x86." + $TestRuntimeVersion) -ItemType File

Describe "list" -Tag "list" {
    Context "When list contains an orphaned alias" {
        $runtimes = (__dnvmtest_run list -PassThru)

        $orphan = $runtimes | Where { $_.Alias -like "*$foobarAlias*" }
        $default = $runtimes | Where { $_.Alias -like "*default*" }

        It "shows orphaned alias correctly"  {
            $orphan | Should Not BeNullOrEmpty
            $orphan.Alias | Should Match "\(missing\)$"
            $orphan.Location | Should BeNullOrEmpty
        }

        It "shows non orphaned alias correctly" {
            $default | Should Not BeNullOrEmpty
            $default.Alias | Should Not Match "\(missing\)"
            $default.Location | Should Not BeNullOrEmpty
        }
    }

    Context "When list contains a global dnx" {
        $runtimeName = GetRuntimeName "CLR" "x86"
        if(Test-Path $UserPath\runtimes\$runtimeName) { del -rec -for $UserPath\runtimes\$runtimeName }
        if(Test-Path $GlobalPath\runtimes\$runtimeName) { del -rec -for $GlobalPath\runtimes\$runtimeName }
        __dnvmtest_run install $TestRuntimeVersion -arch x86 -r "CLR" -g | Out-Null

        $runtimes = (__dnvmtest_run list -PassThru -Detailed)
        It "shows location correctly" {
            $runtimes | Where { $_.Location -like "$GlobalPath\runtimes" } | Should Not BeNullOrEmpty
        }

        if(Test-Path $GlobalPath\runtimes\$runtimeName) { del -rec -for $GlobalPath\runtimes\$runtimeName }
    }
}