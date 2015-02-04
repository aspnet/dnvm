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

# Commands that have been deprecated but do still work.
$DeprecatedCommands = @("unalias")

# Load Environment variables
$RuntimeHomes = $env:KRE_HOME
$UserHome = $env:KRE_USER_HOME

# Default Exit Code
$Script:ExitCode = 0


############################################################
### Below this point, the terms "KVM", "KRE", "K", etc.  ###
### should never be used. Instead, use the Constants     ###
### defined above                                        ###
############################################################

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

$AliasesDir = "$UserHome\alias"
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

function Get-RuntimeName(
    [Parameter(Mandatory=$true)][string]$Version,
    [Parameter(Mandatory=$true)][string]$Architecture,
    [Parameter(Mandatory=$true)][string]$Runtime) {
    "$RuntimePackageName-$Runtime-win-$Architecture.$Version"
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

    $result = @($aliases | Where { !$Name -or ($_.Alias.Contains($Name)) })
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
                            $paramStr += "-$name "
                        }
                        if($_.parameterValue) {
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
                    Write-Console "  $($name.PadRight(10)) $($_.description.Text)"
                }
            }

            if($help.description) {
                Write-Console
                Write-Console $help.description.Text
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

        [Alias("a")]
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