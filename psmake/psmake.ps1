<#
.SYNOPSIS 
A PowerShell based tool which controls a software project build process.

.DESCRIPTION
A PowerShell based tool which controls a software project build process.

.EXAMPLE
C:\Project> .\psmake.ps1 -Target BUILD

Makes all steps associated with BUILD target.

.EXAMPLE
C:\Project> .\psmake.ps1 -MakeDirectory make -Target BUILD -NuGetSource "C:\LocalRepo;https://www.nuget.org/api/v2/" -NuGetExe C:\NuGet\NuGet.exe -NuGetConfig C:\NuGet\NuGet.Config -AnsiConsole -AdditionalParams packageVersion:5.2.2.7,requiredCoverage:85

Locates Makefile.ps1 in 'make' directory and makes all steps associated with BUILD target.
Uses NuGet exe and config file from C:\NuGet directory for fetching packages from C:\LocalRepo and/or https://www.nuget.org/api/v2/.
During steps' execution, $Context.packageVersion and $Context.requiredCoverage variables are available, having '5.2.2.7' and '85' values.
Uses Ansi escape sequences for printing colors.

.EXAMPLE
C:\Project> .\psmake.ps1 -ListAvailableModules

Lists all modules that are available to fetch and use in Makefile.ps1.

.EXAMPLE
C:\Project> .\psmake.ps1 -AddModule -ModuleName psmake.mod-tests-nunit -Version 1.0.0.3

Adds 'psmake.mod-tests-nunit' version 1.0.0.3 to Modules.ps1.

.EXAMPLE
C:\Project> .\psmake.ps1 -ListModules

Lists all modules specified in Modules.ps1.

.EXAMPLE
C:\Project> .\psmake.ps1 -UpdateAllModules

Updates all modules specified in Modules.ps1 to the newest available version.

.EXAMPLE
C:\Project> .\psmake.ps1 -GetVersion

Returns psmake version.

.EXAMPLE
C:\Project> .\psmake.ps1 -Scaffold build-test -MakeDirectory make

Generates initial psmake files in 'make' directory.

#>
[CmdletBinding(DefaultParameterSetName="Make")]
param (
	[Parameter(Mandatory=$true,ParameterSetName="Make")]
	[Alias('t')]
	[ValidateNotNullOrEmpty()]
	# Target to make. All steps annotated with this target would be made.
	[string] $Target,
	
	[Parameter(Mandatory=$true, ParameterSetName="ListAvailableModules")]
	[Alias('lam')]
	# Lists all available modules.
	[switch] $ListAvailableModules,

	[Parameter(Mandatory=$true, ParameterSetName="ListModules")]
	[Alias('lm')]
	# Lists currently installed modules.
	[switch] $ListModules,
	
	[Parameter(Mandatory=$true, ParameterSetName="AddModule")]
	[Alias('am')]
	# Adds a new module to Modules.ps1.
	[switch] $AddModule,

	[Parameter(Mandatory=$true, ParameterSetName="UpdateAllModules")]
	[Alias('uam')]
	# Update all modules from Modules.ps1 to the newest available version.
	[switch] $UpdateAllModules,

	[Parameter(Mandatory=$true, ParameterSetName="Version")]
	# Prints psmake version.
	[switch] $GetVersion,
	
	[Parameter(Mandatory=$true, ParameterSetName="Scaffold")]
	[ValidateSet('empty')]
	# Generates a scaffold psmake setup.
	[string] $Scaffold,

	[Parameter(ParameterSetName="Make")]
	[Alias('ap')]
	# Additional make parameters that would be available for make steps via $Context variable.
	# Expected format: 
	#	-AdditionalParams key1:value1,key2,key3:"abc,def"
	# It will result in $Context.key1 = value1, $Context.key2 = $true, $Context.key3 = "abc,def"
	[string[]] $AdditionalParams,
	
	[Parameter(ParameterSetName="ListAvailableModules")]
	[Parameter(ParameterSetName="ListModules")]
	[Alias('sid')]
	# Returns only package Id.
	[switch] $ShowIdOnly = $false,
	
	[Parameter(Mandatory=$true, ParameterSetName="AddModule")]
	[Alias('mn','Name')]
	[ValidateNotNullOrEmpty()]
	# Module name to add.
	[string] $ModuleName,

	[Parameter(Mandatory=$true, ParameterSetName="AddModule")]
	[Alias('mv','Version')]
	[ValidateNotNullOrEmpty()]
	[ValidatePattern("^[0-9]+(\.[0-9]+){0,3}$")]
	# Module version to add.
	[string] $ModuleVersion,

	[Parameter()]
	[Alias('md')]
	[AllowNull()]
	# Make files directory. A directory where Makefile.ps1 and other files should be placed. By default it is '.'
	[string] $MakeDirectory,

	[Parameter()]
	[AllowNull()]
	# NuGet source to use for fetching modules and packages. It can have semicolon separated urls/paths. If not specified, NuGet.exe would be called without source parameter.
	[string] $NuGetSource,
	
	[Parameter()]
	[AllowNull()]
	# NuGet.exe path like: .nuget\NuGet.exe. If not specified, .nuget\NuGet.exe would be used, and if not found, NuGet.exe would be expected to be on PATH environment variable.
	[string] $NuGetExe,
	
	[Parameter()]
	[AllowNull()]
	# NuGet.Config path like: .nuget\NuGet.Config. If not specified, .nuget\NuGet.Config would be used, and if not found, NuGet.exe would be executed without config file.
	[string] $NuGetConfig,
	
	[Parameter()]
	[Alias('ansi','ac')]
	# Makes Write-Host to write ANSI escaped colors - use only if script is running on terminal supporting ANSI escape sequences.
	[switch] $AnsiConsole
)

function private:Build-Context()
{
	function Load-Defaults()
	{
		$path = "$MakeDirectory\Defaults.ps1"

		if (Test-Path $path) { return & $path }
		return @{}		
	}

	function Add-PropertyValue($object, $name, $value)
	{
		Add-Member -InputObject $object -MemberType NoteProperty -Name $name -Value ''
		$object.$name = $value
	}

	function Add-Property($object, $name, [hashtable]$defaults, [Parameter(ValueFromRemainingArguments = $true)] [object[]]$values)
	{
		if($defaults.Contains($name)) { $values = $values[0],$defaults.Get_Item($name),$values[1..($values.Length-1)]}

		$value = $values | Where-Object { !($_ -eq $null) -and !($_ -eq '')} | Select-Object -first 1
		Add-PropertyValue $object $name $value
	}

	function Locate-NuGetExe()
	{
		if (Test-Path '.nuget\NuGet.exe') { return '.nuget\NuGet.exe' }
		return 'NuGet.exe'
	}

	function Locate-NuGetConfig()
	{
		if (Test-Path '.nuget\NuGet.Config') { return '.nuget\NuGet.Config' }
		return $null
	}

	function Construct-NuGetArgs($cfg)
	{
		$args = @()
		if ($cfg.NuGetSource) { $args+="-Source"; $args+=$cfg.NuGetSource; }
		if($cfg.NuGetConfig) { $args+="-ConfigFile"; $args+=$cfg.NuGetConfig; }
		return $args
	}

	$defaults = Load-Defaults
	$object = New-Object PSObject

	if($AdditionalParams)
	{
		$AdditionalParams | % { $p=$_ -split ':', 2; Add-Property $object $p[0] $defaults $(if($p.Length -eq 2) { $p[1] } else { $true })}
	}

	Add-Property $object 'Target' $defaults $Target 
	Add-Property $object 'AnsiConsole' $defaults if($AnsiConsole.IsPresent) { $AnsiConsole} else { $null }
	Add-Property $object 'MakeDirectory' $defaults $MakeDirectory '.'
	Add-Property $object 'NuGetExe' $defaults $NuGetExe $(Locate-NuGetExe)
	Add-Property $object 'NuGetSource' $defaults $NuGetSource
	Add-Property $object 'NuGetConfig' $defaults $NuGetConfig $(Locate-NuGetConfig)
	Add-PropertyValue $object 'NuGetArgs' $(Construct-NuGetArgs $object)

	# Hide all parameters
	$PSBoundParameters.GetEnumerator() | %{ set-variable -name $_.Key -Option private -ErrorAction SilentlyContinue}
	return $object
}

function private:Get-Version()
{
	return "3.1.0.0"
}

function private:Load-MakeFile()
{
	. $PSScriptRoot\ext\psmake.makefile.ps1;

	$path = "$($Context.MakeDirectory)\Makefile.ps1"
	Write-Header "Loading $path..."
	if (!(Test-Path $path))
	{
		Write-Error "$path does not exist, aborting..."
	}
	[object[]]$steps =  & $path | Where-Object { $_.Target -contains $Context.Target }
	
	for($i=0;$i -lt $steps.Length;$i++) { Write-Host "$($i+1). $($steps[$i].Name)" }
	return $steps

}

function private:Load-Modules($version)
{
	Write-Header "Loading modules"
	. $PSScriptRoot\ext\psmake.modules.ps1
	
	$core = Create-Object @{Name='psmake.core'; File="$PSScriptRoot\ext\psmake.core.ps1"; Version=$version}

	$modules = @{ $core.Name=$core }
	Fetch-Modules | %{ $modules.Add($_.Name, $_) }
	return $modules
}

function private:Load-Environment()
{
	$path = "$($Context.MakeDirectory)\Environment.ps1"
	Write-Header "Loading environment config..."
	$envFiles = @()
	if (!(Test-Path $path)) { Write-Host "$path does not exist, skipping..." }
	else { $envFiles += $path }

	return $envFiles
}

function private:Execute-Steps([array]$steps)
{
	Write-Header "Executing steps..."
	for($i=0;$i -lt $steps.Length;$i++)
	{
		Write-Header -style "*" -header "$($i+1)/$($steps.Length): $($steps[$i].Name)..."
		& ($steps[$i].Body) 
		if (-not $?) { throw 'Last step terminated with error...' }
	}
}

try
{
	$ErrorActionPreference = 'Stop'
	if($AnsiConsole) {. $PSScriptRoot\ext\psmake.ansi.ps1}
	. $PSScriptRoot\ext\psmake.core.ps1
	$Context = Build-Context

	if ($ListAvailableModules) { . $PSScriptRoot\ext\psmake.modules.ps1; List-AvailableModules $ShowIdOnly; }
	elseif ($ListModules) { . $PSScriptRoot\ext\psmake.modules.ps1; List-Modules $ShowIdOnly; }
	elseif ($AddModule) { . $PSScriptRoot\ext\psmake.modules.ps1; Add-Module $ModuleName $ModuleVersion; }
	elseif ($UpdateAllModules) { . $PSScriptRoot\ext\psmake.modules.ps1; Update-Modules; }
	elseif ($GetVersion) { Get-Version }
	elseif ($Scaffold) { . $PSScriptRoot\ext\psmake.scaffold.ps1; Scaffold-Project $scaffold $(Get-Version); }
	else
	{
		$private:steps = Load-MakeFile
		$Modules = Load-Modules $(Get-Version)
		Load-Environment | foreach { Write-Host "Loading $_"; . $_ $($Context.Target); }

		Execute-Steps $steps

		Write-Host -ForegroundColor 'Green' "Make finished :)"
	}
}
catch [Exception]
{
	$_.Exception | format-list -force | Out-String | Write-Host -ForegroundColor 'DarkRed'
	$_.InvocationInfo |Format-List | Out-String | Write-Host -ForegroundColor 'DarkRed'
	Write-Host -ForegroundColor 'Red' "Make failed :("
	throw
}
finally
{
	if($AnsiConsole) { remove-item function:Write-Host }
}