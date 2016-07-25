# Installs the K Version Manager by downloading the latest version from the GitHub repository
param(
    [Parameter(Position=0)][string]$Branch = "master",
    [Parameter(Position=1)][string]$Repository = "aspnet/kvm")

$tempPath = Join-Path $env:TEMP "kvminstall"
$kvmPs1Path = Join-Path $tempPath "kvm.ps1"
$kvmCmdPath = Join-Path $tempPath "kvm.cmd"

Write-Host "Using temporary directory: $tempPath"
if (!(Test-Path $tempPath)) { md $tempPath | Out-Null }


$webClient = New-Object System.Net.WebClient
Write-Host "Downloading KVM.ps1 to $kvmPs1Path"
$webClient.DownloadFile("https://raw.githubusercontent.com/$Repository/$Branch/src/kvm.ps1", $kvmPs1Path)
Write-Host "Downloading KVM.cmd to $kvmCmdPath"
$webClient.DownloadFile("https://raw.githubusercontent.com/$Repository/$Branch/src/kvm.cmd", $kvmCmdPath)
Write-Host "Installing KVM"
& $kvmCmdPath setup