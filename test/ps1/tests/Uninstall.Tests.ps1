function DefineUninstallTests($clr, $arch, $os) {
    $runtimeHome = $UserPath
    $alias = "uninstall_test_$arch_$clr"

    if($clr -eq "CoreCLR") {
        $fxName = "Asp.NetCore,Version=v5.0"
    } else {
        $fxName = "Asp.Net,Version=v5.0"
    }

    $runtimeName = GetRuntimeName $clr $arch -OS:$os
    $runtimeRoot = "$runtimeHome\runtimes\$runtimeName"

    Context "When uninstalling $clr on $arch for $os" {
        It "removes the runtime folder" {
            # Never crossgen in the automated tests since it takes a loooong time :(.
            if($clr -eq "mono") {
                __dnvmtest_run install $TestRuntimeVersion -arch $arch -r $clr -os $os -nonative | Out-Null
            } else {
                __dnvmtest_run install $TestRuntimeVersion -arch $arch -r $clr -alias $alias -os $os -nonative | Out-Null
            }

            $runtimeRoot | Should Exist
            __dnvmtest_run uninstall $TestRuntimeVersion -arch $arch -r $clr -os $os | Out-Null
            $runtimeRoot | Should Not Exist

            $__dnvmtest_exit | Should Be 0
        }
    }
}

Describe "uninstall" -Tag "uninstall" {
    DefineUninstallTests "CLR" "x86" "win"
    DefineUninstallTests "CLR" "x64" "win"
    DefineUninstallTests "CoreCLR" "x86" "win"
    DefineUninstallTests "CoreCLR" "x64" "win"
    DefineUninstallTests "CoreCLR" "x64" "linux"
    DefineUninstallTests "CoreCLR" "x64" "darwin"
    DefineUninstallTests "Mono" "x86" "linux"

    Context "When uninstalling a runtime that isn't installed" {
        # Clear active runtime
        __dnvmtest_run use none | Out-Null

        $runtimeName = GetRuntimeName "CLR" "x86"
        $runtimePath = "$UserPath\runtimes\$runtimeName"
        __dnvmtest_run uninstall $TestRuntimeVersion -arch x86 -r "CLR" | Out-Null

        It "says runtime is not installed" {
            __dnvmtest_run uninstall $TestRuntimeVersion -arch x86 -r "CLR" | Out-Null
            ($__dnvmtest_out.Trim() -like "*'$runtimeName' is not installed*") | Should Be $true
            $runtimePath | Should Not Exist
        }
    }

    Context "When uninstalling" {
        $runtimeName = GetRuntimeName "CLR" "x86"
        if(Test-Path $UserPath\runtimes\$runtimeName) { del -rec -for $UserPath\runtimes\$runtimeName }
        if(Test-Path $GlobalPath\runtimes\$runtimeName) { del -rec -for $GlobalPath\runtimes\$runtimeName }

        __dnvmtest_run install $TestRuntimeVersion -arch x86 -r "CLR" -g | Out-Null
        It "it can uninstall a global runtime" {
            
            __dnvmtest_run uninstall $TestRuntimeVersion -arch x86 -r "CLR"
            ($__dnvmtest_out.Trim() -like "*Removed '$GlobalPath\runtimes\$runtimeName'*") | Should Be $true
            "$GlobalPath\runtimes\$runtimeName" | Should Not Exist
        }
    }
}
