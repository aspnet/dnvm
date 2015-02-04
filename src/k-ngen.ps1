param(
  [Parameter(Mandatory=$true)]
  [string]
  $runtimeBin,
  
  [Parameter(Mandatory=$true)]
  [string]
  $architecture
)

if ($architecture -eq 'x64') {
  $regView = [Microsoft.Win32.RegistryView]::Registry64
}
elseif ($architecture -eq 'x86') {
  $regView = [Microsoft.Win32.RegistryView]::Registry32
}
else {
  Write-Error "Installation does not understand architecture $architecture, skipping ngen..."
  Exit -1
}

$regHive = [Microsoft.Win32.RegistryHive]::LocalMachine
$regKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey($regHive, $regView)
$frameworkPath = $regKey.OpenSubKey("SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full").GetValue("InstallPath")
$ngenExe = Join-Path $frameworkPath 'ngen.exe'

foreach ($bin in Get-ChildItem $runtimeBin -Filter "Microsoft.CodeAnalysis*.dll") {
  &"$ngenExe" "install" "$($bin.FullName)"
}

Exit 0