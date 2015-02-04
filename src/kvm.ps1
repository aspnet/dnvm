### Constants
$ProductVersion="1.0.0"
$BuildNumber="{{BUILD_NUMBER}}"
$BuildRelease="{{BUILD_RELEASE}}"
$BuildVersion="$ProductVersion-$BuildRelease-$BuildNumber"
if($BuildNumber -eq "{{BUILD_NUMBER}}") {
    $BuildVersion="$ProductVersion-HEAD"
}

Set-Variable -Option Constant "CommandName" ([IO.Path]::GetFileNameWithoutExtension($MyInvocation.MyCommand.Name))
Set-Variable -Option Constant "CommandFriendlyName" "K Runtime Version Manager"
Set-Variable -Option Constant "DefaultUserDirectoryName" ".k"
Set-Variable -Option Constant "RuntimePackageName" "kre"
Set-Variable -Option Constant "DefaultFeed" "https://www.myget.org/F/aspnetvnext/api/v2"
Set-Variable -Option Constant "CrossGenCommand" "k-crossgen"

Set-Variable -Option Constant "OptionPadding" 20

# Commands that have been deprecated but do still work.
$DeprecatedCommands = @("unalias")

# Load Environment variables
$RuntimeHomes = $env:KRE_HOME
$UserHome = $env:KRE_USER_HOME
$ActiveFeed = $env:KRE_FEED

# Default Exit Code
$Script:ExitCode = 0

############################################################
### Below this point, the terms "KVM", "KRE", "K", etc.  ###
### should never be used. Instead, use the Constants     ###
### defined above                                        ###
############################################################

if(!$ActiveFeed) {
    $ActiveFeed = $DefaultFeed
}

# Determine where runtimes can exist (RuntimeHomes)
if(!$RuntimeHomes) {
    # Set up a default value for the runtime home
    $RuntimeHomes = "$env:USERPROFILE\$DefaultUserDirectoryName"
} else {
    $RuntimeHomes = [Environment]::ExpandEnvironmentVariables($RuntimeHomes)
}

$RuntimeHomes = $RuntimeHomes.Split(";")

# Determine the default installation directory (UserHome)
if(!$UserHome) {
    $pf = $env:ProgramFiles
    if(Test-Path "env:\ProgramFiles(x86)") {
        $pf32 = cat "env:\ProgramFiles(x86)"
    }

    # Canonicalize so we can do StartsWith tests
    if(!$pf.EndsWith("\")) { $pf += "\" }
    if($pf32 -and !$pf32.EndsWith("\")) { $pf32 += "\" }

    $UserHome = $RuntimeHomes | Where-Object {
        # Take the first path that isn't under program files
        !($_.StartsWith($pf) -or $_.StartsWith($pf32))
    } | Select-Object -First 1

    if(!$UserHome) {
        $UserHome = "$env:USERPROFILE\$DefaultUserDirectoryName"
    }
}

Write-Debug "Running $CommandName"
Write-Debug "Runtime Homes: $RuntimeHomes"
Write-Debug "User Home: $UserHome"

$AliasesDir = Join-Path $UserHome "alias"
$RuntimesDir = Join-Path $UserHome "runtimes"
$Aliases = $null

### Helper Functions
function Write-Console {
    Write-Host @args    
}

function Write-Usage {
    Write-Console "$CommandFriendlyName Version $BuildVersion"
    Write-Console
    Write-Console "Usage: $CommandName <command> [<arguments...>]"
}

function Get-RuntimeAlias {
    if($Aliases -eq $null) {
        Write-Debug "Scanning for aliases in $AliasesDir"
        if(Test-Path $AliasesDir) {
            $Aliases = @(Get-ChildItem ($UserHome + "\alias\") | Select-Object @{label='Alias';expression={$_.BaseName}}, @{label='Name';expression={Get-Content $_.FullName }})
        } else {
            $Aliases = @()
        }
    }
    $Aliases
}

function IsOnPath {
    param($dir)

    $env:Path.Split(';') -icontains $dir
}

function Get-RuntimeId(
    [Parameter(Mandatory=$true)][string]$Architecture,
    [Parameter(Mandatory=$true)][string]$Runtime) {

    "$RuntimePackageName-$Runtime-win-$Architecture"
}

function Get-RuntimeName(
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Architecture,
    [Parameter(Mandatory=$true)][string]$Runtime) {

    $aliasPath = Join-Path $AliasesDir "$Version.txt"

    if(Test-Path $aliasPath) {
        Get-Content $aliasPath
    }
    else {
        "$(Get-RuntimeId $Architecture $Runtime).$Version"
    }
}

filter List-Parts {
    param($aliases)

    $binDir = Join-Path $_.FullName "bin"
    if (!(Test-Path $binDir)) {
        return
    }
    $active = IsOnPath $binDir
    
    $fullAlias=""
    $delim=""

    foreach($alias in $aliases) {
        if($_.Name.Split('\', 2) -contains $alias.Name) {
            $fullAlias += $delim + $alias.Alias
            $delim = ", "
        }
    }

    $parts1 = $_.Name.Split('.', 2)
    $parts2 = $parts1[0].Split('-', 4)
    return New-Object PSObject -Property @{
        Active = $active
        Version = $parts1[1]
        Runtime = $parts2[1]
        OperatingSystem = $parts2[2]
        Architecture = $parts2[3]
        Location = $_.Parent.FullName
        Alias = $fullAlias
    }
}

function Read-Alias($Name) {
    Write-Debug "Listing aliases matching '$Name'"

    $aliases = Get-RuntimeAlias

    $result = @($aliases | Where-Object { !$Name -or ($_.Alias.Contains($Name)) })
    if($Name -and ($result.Length -eq 1)) {
        Write-Console "Alias '$Name' is set to '$($result[0].Name)'"
    } elseif($Name -and ($result.Length -eq 0)) {
        $Script:ExitCode = 1
        Write-Warning "Alias does not exist: '$Name'"
    } else {
        $result
    }
}

function Write-Alias {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Version,
        [Parameter(Mandatory=$true)][string]$Architecture,
        [Parameter(Mandatory=$true)][string]$Runtime)

    $runtimeFullName = Get-RuntimeName $Version $Architecture $Runtime
    $aliasFilePath = Join-Path $AliasesDir "$Name.txt"
    $action = if (Test-Path $aliasFilePath) { "Updating" } else { "Setting" }
    
    if(!(Test-Path $AliasesDir)) {
        Write-Debug "Creating alias directory: $AliasesDir"
        New-Item -Type Directory $AliasesDir | Out-Null
    }
    Write-Console "$action alias '$Name' to '$runtimeFullName'"
    $runtimeFullName | Out-File $aliasFilePath ascii
}

function Delete-Alias {
    param(
        [Parameter(Mandatory=$true)][string]$Name)

    $aliasPath = Join-Path $AliasesDir "$Name.txt"
    if (Test-Path -literalPath "$aliasPath") {
        Write-Console "Removing alias $Name"

        # Delete with "-Force" because we already confirmed above
        Remove-Item -literalPath $aliasPath -Force
    } else {
        Write-Warning "Cannot remove alias, '$Name' is not a valid alias name"
        $Script:ExitCode = 1 # Return non-zero exit code for scripting
    }
}

function Apply-Proxy {
param(
  [System.Net.WebClient] $wc,
  [string]$Proxy
)
  if (!$Proxy) {
    $Proxy = $env:http_proxy
  }
  if ($Proxy) {
    $wp = New-Object System.Net.WebProxy($Proxy)
    $pb = New-Object UriBuilder($Proxy)
    if (!$pb.UserName) {
        $wp.Credentials = [System.Net.CredentialCache]::DefaultCredentials
    } else {
        $wp.Credentials = New-Object System.Net.NetworkCredential($pb.UserName, $pb.Password)
    }
    $wc.Proxy = $wp
  }
}

function Find-Latest {
    param(
        [string]$platform,
        [string]$architecture,
        [string]$Feed,
        [string]$Proxy
    )
    if(!$Feed) { $Feed = $ActiveFeed }

    Write-Console "Determining latest version"

    $url = "$Feed/GetUpdates()?packageIds=%27$RuntimePackageName-$platform-win-$architecture%27&versions=%270.0%27&includePrerelease=true&includeAllVersions=false"

    # NOTE: DO NOT use Invoke-WebRequest. It requires PowerShell 4.0!

    $wc = New-Object System.Net.WebClient
    Apply-Proxy $wc -Proxy:$Proxy
    Write-Debug "Downloading $url ..."
    [xml]$xml = $wc.DownloadString($url)

    $version = Select-Xml "//d:Version" -Namespace @{d='http://schemas.microsoft.com/ado/2007/08/dataservices'} $xml

    if (![String]::IsNullOrWhiteSpace($version)) {
        $version
    }
}

function Get-PackageVersion() {
    param(
        [string] $runtimeFullName
    )
    return $runtimeFullName -replace '[^.]*.(.*)', '$1'
}

function Get-PackageRuntime() {
    param(
        [string] $runtimeFullName
    )
    return $runtimeFullName -replace "$RuntimePackageName-([^-]*).*", '$1'
}

function Get-PackageArch() {
    param(
        [string] $runtimeFullName
    )
    return $runtimeFullName -replace "$RuntimePackageName-[^-]*-[^-]*-([^.]*).*", '$1'
}

function Download-Package(
    [string]$Version,
    [string]$Architecture,
    [string]$Runtime,
    [string]$DestinationFile,
    [string]$Feed,
    [string]$Proxy) {

    if(!$Feed) { $Feed = $ActiveFeed }
    
    $url = "$Feed/package/" + (Get-RuntimeId $Architecture $Runtime) + "/" + $Version
    
    Write-Console "Downloading $runtimeFullName from $feed"

    $wc = New-Object System.Net.WebClient
    Apply-Proxy $wc -Proxy:$Proxy
    Write-Debug "Downloading $url ..."
    $wc.DownloadFile($url, $DestinationFile)
}

function Unpack-Package([string]$DownloadFile, [string]$UnpackFolder) {
    Write-Debug "Unpacking $DownloadFile to $UnpackFolder"

    $compressionLib = [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')

    if($compressionLib -eq $null) {
      try {
          # Shell will not recognize nupkg as a zip and throw, so rename it to zip
          $runtimeZip = [System.IO.Path]::ChangeExtension($DownloadFile, "zip")
          Rename-Item $runtimeFile $runtimeZip
          # Use the shell to uncompress the nupkg
          $shell_app=new-object -com shell.application
          $zip_file = $shell_app.namespace($runtimeZip)
          $destination = $shell_app.namespace($UnpackFolder)
          $destination.Copyhere($zip_file.items(), 0x14) #0x4 = don't show UI, 0x10 = overwrite files
      }
      finally {
        # Clean up the package file itself.
        Remove-Item $runtimeZip -Force
      }
    } else {
        [System.IO.Compression.ZipFile]::ExtractToDirectory($DownloadFile, $UnpackFolder)
        
        # Clean up the package file itself.
        Remove-Item $DownloadFile -Force
    }

    If (Test-Path -LiteralPath ($UnpackFolder + "\[Content_Types].xml")) {
        Remove-Item -LiteralPath ($UnpackFolder + "\[Content_Types].xml")
    }
    If (Test-Path ($UnpackFolder + "\_rels\")) {
        Remove-Item -LiteralPath ($UnpackFolder + "\_rels\") -Force -Recurse
    }
    If (Test-Path ($UnpackFolder + "\package\")) {
        Remove-Item -LiteralPath ($UnpackFolder + "\package\") -Force -Recurse
    }
}

### Commands

<#
.SYNOPSIS
    Displays a list of commands, and help for specific commands
.PARAMETER Command
    A specific command to get help for
#>
function command-help {
    [CmdletBinding(DefaultParameterSetName="GeneralHelp")]
    param(
        [Parameter(Mandatory=$true,Position=0,ParameterSetName="SpecificCommand")][string]$Command,
        [switch]$PassThru)

    if($Command) {
        $help = Get-Help "command-$Command"
        $cmd = Get-Command "command-$Command"
        if($PassThru) {
            $help
        } else {
            Write-Console "$CommandName-$Command"
            Write-Console "  $($help.Synopsis)"
            Write-Console
            Write-Console "usage:"
            $help.Syntax.syntaxItem | ForEach-Object {
                Write-Console "  $CommandName $Command" -noNewLine
                if($_.parameter) {
                    $_.parameter | ForEach-Object {
                        $cmdParam = $cmd.Parameters[$_.name]
                        $name = $_.name
                        if($cmdParam.Aliases.Length -gt 0) {
                            $name = $cmdParam.Aliases | Sort-Object | Select-Object -First 1
                        }

                        $paramStr = "";
                        if($_.position -eq "Named") {
                            $paramStr += "-$name"
                        }
                        if($_.parameterValue) {
                            if($_.position -eq "Named") {
                                $paramStr += " "
                            }
                            $paramStr += "<$($_.name)>"
                        }

                        if($_.required -ne "true") {
                            $paramStr = "[$paramStr]"
                        }
                        Write-Console " $paramStr" -noNewLine
                    }
                }
                Write-Console
            }

            if($help.parameters -and $help.parameters.parameter) {
                Write-Console
                Write-Console "options:"
                $help.parameters.parameter | ForEach-Object {
                    $cmdParam = $cmd.Parameters[$_.name]
                    $name = $_.name
                    if($cmdParam.Aliases.Length -gt 0) {
                        $name = $cmdParam.Aliases | Sort-Object | Select-Object -First 1
                    }
                    if($_.position -eq "Named") {
                        $name="-$name"
                    } else {
                        $name="<$name>"
                    }
                    Write-Console "  $($name.PadRight($OptionPadding)) $($_.description.Text)"
                }
            }

            if($help.description) {
                Write-Console
                Write-Console "remarks:"
                Write-Console (
                    $help.description.Text.Split(@("`r", "`n"), "RemoveEmptyEntries") | 
                        ForEach-Object { "  $_" })
            }

            if($DeprecatedCommands -contains $Command) {
                Write-Warning "This command has been deprecated and should not longer be used"
            }
        }
    } else {
        Write-Usage
        Write-Console
        Write-Console "Commands: "
        Get-Command "command-*" | 
            ForEach-Object {
                $h = Get-Help $_.Name
                $name = $_.Name.Substring(8)
                if($DeprecatedCommands -notcontains $name) {
                    Write-Console "    $($name.PadRight(10)) $($h.Synopsis)"
                }
            }
    }
}

<#
.SYNOPSIS
    Lists available runtimes
.PARAMETER PassThru
    Set this switch to return unformatted powershell objects for use in scripting
#>
function command-list {
    param(
        [Parameter(Mandatory=$false)][switch]$PassThru)
    $aliases = Get-RuntimeAlias

    $items = @()
    $RuntimeHomes | ForEach-Object {
        Write-Debug "Scanning $_ for runtimes..."
        if (Test-Path "$_\runtimes") {
            $items += Get-ChildItem "$_\runtimes\$RuntimePackageName-*" | List-Parts $aliases
        }
    }

    if($PassThru) {
        $items
    } else {
        $items | 
            Sort-Object Version, Runtime, Architecture, Alias | 
            Format-Table -AutoSize -Property @{name="Active";expression={if($_.Active) { "*" } else { "" }};alignment="center"}, "Version", "Runtime", "Architecture", "Location", "Alias"
    }
}

<#
.SYNOPSIS
    Lists and manages aliases
.PARAMETER Name
    The name of the alias to read/write/delete
.PARAMETER Version
    The version to assign to the new alias
.PARAMETER Architecture
    The architecture of the runtime to assign to this alias
.PARAMETER Runtime
    The flavor of the runtime to assign to this alias
.PARAMETER Delete
    Set this switch to delete the alias with the specified name
#>
function command-alias {
    param(
        [Alias("d")]
        [Parameter(ParameterSetName="Delete",Mandatory=$true)]
        [switch]$Delete,

        [Parameter(ParameterSetName="Read",Mandatory=$false,Position=0)]
        [Parameter(ParameterSetName="Write",Mandatory=$true,Position=0)]
        [Parameter(ParameterSetName="Delete",Mandatory=$true,Position=0)]
        [string]$Name,
        
        [Parameter(ParameterSetName="Write",Mandatory=$true,Position=1)]
        [string]$Version,

        [Alias("arch")]
        [ValidateSet("x86","amd64")]
        [Parameter(ParameterSetName="Write", Mandatory=$false)]
        [string]$Architecture = "x86",

        [Alias("r")]
        [ValidateSet("clr","coreclr")]
        [Parameter(ParameterSetName="Write")]
        [string]$Runtime = "clr")

    switch($PSCmdlet.ParameterSetName) {
        "Read" { Read-Alias $Name }
        "Write" { Write-Alias $Name $Version -Architecture $Architecture -Runtime $Runtime }
        "Delete" { Delete-Alias $Name }
    }
}

<#
.SYNOPSIS
    [DEPRECATED] Removes an alias
.PARAMETER Name
    The name of the alias to remove
#>
function command-unalias {
    param(
        [Parameter(Mandatory=$true,Position=0)][string]$Name)
    Write-Warning "This command is obsolete. Use '$CommandName alias -d' instead"
    command-alias -Delete -Name $Name
}

<#
.SYNOPSIS
    Installs a version of the runtime
.PARAMETER VersionOrNuPkg
    The version to install from the current channel, the path to a '.nupkg' file to install, or 'latest' to
    install the latest available version from the current channel.
.PARAMETER Architecture
    The processor architecture of the runtime to install (default: x86)
.PARAMETER Runtime
    The runtime flavor to install (default: clr)
.PARAMETER Alias
    Set alias <Alias> to the installed runtime
.PARAMETER Force
    Overwrite an existing runtime if it already exists
.PARAMETER Proxy
    Use the given address as a proxy when accessing remote server
.Parameter NoNative
    Skip generation of native images when installing coreclr runtime flavors

.DESCRIPTION
    A proxy can also be specified by using the 'http_proxy' environment variable

#>
function command-install {
    param(
        [Parameter(Mandatory=$false, Position=0)]
        [string]$VersionOrNuPkg,

        [Alias("arch")]
        [ValidateSet("x86","x64")]
        [Parameter(Mandatory=$false)]
        [string]$Architecture = "x86",

        [Alias("r")]
        [ValidateSet("clr","coreclr")]
        [Parameter(Mandatory=$false)]
        [string]$Runtime = "clr",

        [Alias("a")]
        [Parameter(Mandatory=$false)]
        [string]$Alias,

        [Alias("f")]
        [Parameter(Mandatory=$false)]
        [switch]$Force,

        [Parameter(Mandatory=$false)]
        [string]$Proxy,

        [Parameter(Mandatory=$false)]
        [switch]$NoNative)

    if(!$VersionOrNuPkg) {
        Write-Warning "A version, nupkg path, or the string 'latest' must be provided."
        command-help install
        return
    }

    if ($VersionOrNuPkg -eq "latest") {
        $VersionOrNuPkg = Find-Latest $Runtime $Architecture
    }

    $IsNuPkg = $VersionOrNuPkg.EndsWith(".nupkg")

    if ($IsNuPkg) {
        if(!(Test-Path $VersionOrNuPkg)) {
            throw "Unable to locate package file: '$VersionOrNuPkg'"
        }
        $runtimeFullName = [System.IO.Path]::GetFileNameWithoutExtension($VersionOrNuPkg)
        $Architecture = Get-PackageArch $runtimeFullName
        $Runtime = Get-PackageRuntime $runtimeFullName
    } else {
        $runtimeFullName = Get-RuntimeName $VersionOrNuPkg $Architecture $Runtime
    }

    Write-Debug "Preparing to install runtime '$runtimeFullName'"
    Write-Debug "Architecture: $Architecture"
    Write-Debug "Runtime: $Runtime"

    $RuntimeFolder = Join-Path $RuntimesDir $runtimeFullName
    Write-Debug "Destination: $RuntimeFolder"

    if((Test-Path $RuntimeFolder) -and $Force) {
        Write-Console "Cleaning existing installation..."
        Remove-Item $RuntimeFolder -Recurse -Force
    }

    if(Test-Path $RuntimeFolder) {
        Write-Warning "Target folder '$RuntimeFolder' already exists"
        $Script:ExitCode = 1
        return
    }

    $UnpackFolder = Join-Path $RuntimesDir "temp"
    $DownloadFile = Join-Path $UnpackFolder "$runtimeFullName.nupkg"

    if(Test-Path $UnpackFolder) {
        Write-Debug "Cleaning temporary directory $UnpackFolder"
        Remove-Item $UnpackFolder -Recurse -Force
    }
    New-Item -Type Directory $UnpackFolder | Out-Null

    if($IsNuPkg) {
        Copy-Item $VersionOrNuPkg $DownloadFile
    } else {
        # Download the package
        Download-Package $VersionOrNuPkg $Architecture $Runtime $DownloadFile -Proxy:$Proxy
    }

    Unpack-Package $DownloadFile $UnpackFolder

    New-Item -Type Directory $RuntimeFolder -Force | Out-Null
    Write-Console "Installing to $RuntimeFolder"
    Write-Debug "Moving package contents to $RuntimeFolder"
    Move-Item "$UnpackFolder\*" $RuntimeFolder
    Write-Debug "Cleaning temporary directory $UnpackFolder"
    Remove-Item $UnpackFolder -Force | Out-Null

    $PackageVersion = Get-PackageVersion $runtimeFullName

    command-use $PackageVersion

    if($Alias) {
        command-alias $Alias $PackageVersion
    }

    if ($runtimeFullName.Contains("CoreCLR")) {
        if ($NoNative) {
          Write-Console "Skipping native image compilation."
        }
        else {
          Write-Console "Compiling native images for $runtimeFullName to improve startup performance..."
          Start-Process $CrossGenCommand -Wait
          Write-Console "Finished native image compilation."
        }
    }
}

### The main "entry point"

# Read arguments

$cmd = $args[0]

if($args.Length -gt 1) {
    $cmdargs = $args[1..($args.Length-1)]
} else {
    $cmdargs = @()
}

if(!$cmd) {
    Write-Warning "You must specify a command!"
    $cmd = "help"
}

# Check for the command
if(Get-Command -Name "command-$cmd" -ErrorAction SilentlyContinue) {
    & "command-$cmd" @cmdargs
}
else {
    Write-Warning "Unknown command: '$cmd'"
    & command-help
}

exit $Script:ExitCode