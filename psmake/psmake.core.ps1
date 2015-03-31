<#
.SYNOPSIS 
Calls external program, and throws an exception if operation is unsuccessful.

.DESCRIPTION
Calls external program, and throws an exception if operation is unsuccessful.

The command and arguments are printed with Write-Host before execution.
The command output is printed with Write-Host on console.
#>
function Call-Program (
    [parameter(Position=0)]
    # Command to execute.
    $command, 

    [parameter(Position=1, ValueFromRemainingArguments=$true)] 
    # Command arguments.
    $args) 
{
	Write-Host $command $args -ForegroundColor "Gray"
	& $command $args | Write-Host -ForegroundColor "Magenta"
	if (-not $?) { throw "A program execution was not successful (Exit code: $LASTEXITCODE)." }
}

set-alias call Call-Program

<#
.SYNOPSIS 
Prints header in green color.

.DESCRIPTION
Prints header in green color, in format:

------------------------------------------------------------
- Header
------------------------------------------------------------
#>
function Write-Header(
    # Header text
    $header,
    # Header border style. '-' if not specified 
    $style="-")
{
	Write-Host
	Write-Host "$($style * 60)" -foregroundcolor "DarkGreen"
	Write-Host "$style $header" -foregroundcolor "Green"
	Write-Host "$($style * 60)" -foregroundcolor "DarkGreen"
	Write-Host
}

<#
.SYNOPSIS 
Prints status in cyan color.

.DESCRIPTION
Prints status in cyan color in format:

- Status
------------------------------------------------------------
#>
function Write-Status(
    # Status text
    $text,
    # Status border style. '-' if not specified 
    $style="-")
{
	Write-Host
	Write-Host "$style $text" -foregroundcolor "Cyan"
	Write-Host "$($style * 60)" -foregroundcolor "DarkCyan"
	Write-Host
}

<#
.SYNOPSIS 
Fetches NuGet package of specified name and version.

.DESCRIPTION
Fetches NuGet package of specified name and version.
Function returns path to fetched package.
#>
function Fetch-Package(
    # Package name to fetch
    $name,
    # Package version to fetch 
    $version)
{
	Write-Host "Fetching $name ver. $version..."
	if (!$Context.MakeDirectory) {$packageDir='packages'}
	else {$packageDir="$($Context.MakeDirectory)\packages"}
	
    $nuArgs=$Context.NuGetArgs
	call $Context.NugetExe install $name -Version $version -OutputDirectory "$packageDir" -Verbosity detailed @nuArgs
	return ".\$packageDir\$name.$version"
}

<# 
.SYNOPSIS
Creates object with properties defined in $hash parameter
#>
function Create-Object([hashtable] $hash)
{
    $object = New-Object PSObject
    $hash.GetEnumerator() | % { 
        Add-Member -InputObject $object -MemberType NoteProperty -Name $_.Key -Value ""
        $object.$($_.Key) = $_.Value
    }
    return $object
}

<# 
.SYNOPSIS
Provides path to module specified in $moduleName.

.EXAMPLE
PS> . (Require-Module 'psmake.mod.my-module')

Loads 'psmake.mod.my-module' module, making all it's methods available in current scope.
#>
function Require-Module([string] $moduleName)
{
	if(!$Modules.Contains($moduleName)) { throw "Module $moduleName is not added. Please add it first with psmake.ps1 -AddModule."}
	return $Modules.Get_Item($moduleName).File

}

set-alias require Require-Module

<#
.SYNOPSIS

Makes a script-block for remote or local execution, that would allow to access all psmake core methods and $Context variable.
#>
function Make-ScriptBlock([string]$code, [boolean]$remote=$true)
{	
    if ($remote) 
    { 
        [string]$core = require 'psmake.core'
        $code = "`$Context=`$using:Context; `$Modules=`$using:Modules; . $core; $code"
    }
	return [scriptblock]::Create($code)
}