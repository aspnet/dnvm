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

# Load Environment variables
$RuntimeHomes = $env:KRE_HOME
$UserHome = $env:KRE_USER_HOME


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
function Write-Usage {
    Write-Host "$CommandFriendlyName Version $BuildVersion"
    Write-Host
    Write-Host "Usage: $CommandName <command> [<arguments...>]"
}

function Get-Alias {
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
        [Parameter(Mandatory=$true,Position=0,ParameterSetName="SpecificCommand")][string]$Command)

    if($Command) {
        $help = Get-Help "command-$Command"
        if($PassThru) {
            $help
        } else {
            Write-Host "$CommandName-$Command"
            Write-Host "  $($help.Synopsis)"
            Write-Host
            Write-Host "usage:"
            $help.Syntax.syntaxItem | ForEach-Object {
                Write-Host "  $CommandName $Command" -noNewLine
                if($_.parameter) {
                    $_.parameter | ForEach-Object {
                        $paramStr = "";
                        if($_.position -ne "Named") {
                            $paramStr += "["
                        }
                        $paramStr += "-$($_.name)"
                        if($_.position -ne "Named") {
                            $paramStr += "]"
                        }
                        if($_.parameterValue) {
                            $paramStr += " <$($_.parameterValue)>"
                        }

                        if($_.required -ne "true") {
                            $paramStr = "[$paramStr]"
                        }
                        Write-Host " $paramStr" -noNewLine
                    }
                }
                Write-Host
            }

            if($help.parameters -and $help.parameters.parameter) {
                Write-Host
                Write-Host "options:"
                $help.parameters.parameter | ForEach-Object {
                    Write-Host "  -$($_.name.PadRight(15)) $($_.description.Text)"
                }
            }

            if($help.description) {
                Write-Host
                Write-Host $help.description.Text
            }
        }
    } else {
        Write-Usage
        Write-Host
        Write-Host "Commands: "
        Get-Command "command-*" | 
            ForEach-Object {
                $h = Get-Help $_.Name
                $name = $_.Name.Substring(8)
                Write-Host "    $($name.PadRight(10)) $($h.Synopsis)"
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
    $aliases = Get-Alias

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