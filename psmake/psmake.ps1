<#
.SYNOPSIS 
A PowerShell based tool which controls a software project build process.

.DESCRIPTION
A PowerShell based tool which controls a software project build process.

.EXAMPLE
C:\Project> .\psmake.ps1 -Target BUILD

Makes all steps associated with BUILD target.

.EXAMPLE
C:\Project> .\psmake.ps1 -MakeDirectory make -Target BUILD -NugetRepositoryUrl "C:\LocalRepo;https://www.nuget.org/api/v2/" -NuGetExe C:\NuGet\NuGet.exe -NuGetConfig C:\NuGet\NuGet.Config -AnsiConsole -AdditionalParams packageVersion:5.2.2.7,requiredCoverage:85

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
	
	[Parameter(Mandatory=$true, ParameterSetName="AddModule")]
	[Alias('mn','Name')]
	[ValidateNotNullOrEmpty()]
    # Module name to add.
	[string] $ModuleName,

	[Parameter(ParameterSetName="AddModule")]
	[Alias('mv','Version')]
	[AllowNull()]
	[ValidatePattern("^[0-9]+(\.[0-9]+){0,3}$")]
    # Module version to add. If not specified, the newest one would be added.
	[string] $ModuleVersion = $null,

	[Parameter()]
	[Alias('md')]
	[ValidateNotNullOrEmpty()]
    # Make files directory. A directory where Makefile.ps1 and other files should be placed.
	[string] $MakeDirectory = ".",

	[Parameter()]
	[Alias('Source','nru')]
	[AllowNull()]
    # NuGet source to use for fetching modules and packages. It can have semicolon separated urls/paths. If not specified, NuGet.exe would be called without source parameter.
	[string] $NugetRepositoryUrl,
	
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
	[switch] $AnsiConsole = $false,
	
    [Parameter(Mandatory=$true,ParameterSetName="Make")]
	[Alias('t')]
    [ValidateNotNullOrEmpty()]
    # Target to make. All steps annotated with this target would be made.
	[string] $Target,

	[Parameter(ParameterSetName="Make")]
	[Alias('ap')]
    # Additional make parameters that would be available for make steps via $Context variable.
    # Expected format: 
    #    -AdditionalParams key1:value1,key2,key3:"abc,def"
    # It will result in $Context.key1 = value1, $Context.key2 = $true, $Context.key3 = "abc,def"
	[string[]] $AdditionalParams
)

function private:BuildContext()
{
	function AddMember($object, $name, $value)
	{
		Add-Member -InputObject $object -MemberType NoteProperty -Name $name -Value ''
		$object.$name = $value
	}

    function LocateNuGetExe()
    {
        if ($NuGetExe) { return $NuGetExe }
        if (Test-Path '.nuget\NuGet.exe') { return '.nuget\NuGet.exe' }
        return 'NuGet.exe'
    }

    function LocateNuGetConfig()
    {
        if ($NuGetConfig) { return $NuGetConfig }
        if (Test-Path '.nuget\NuGet.Config') { return '.nuget\NuGet.Config' }
        return $null
    }

    function ConstructNuGetArgs()
    {
        $args = @()
        if ($NugetRepositoryUrl) { $args+="-Source"; $args+=$NugetRepositoryUrl; }
        $cfg = LocateNuGetConfig
        if($cfg) { $args+="-ConfigFile"; $args+=$cfg; }
        return $args
    }

	$object = New-Object PSObject

    if($AdditionalParams)
	{
        $AdditionalParams | % { $p=$_ -split ':', 2; AddMember $object $p[0] $(if($p.Length -eq 2) { $p[1] } else { $true })}
    }

    AddMember $object 'Target' $Target
    AddMember $object 'AnsiConsole' $AnsiConsole
    AddMember $object 'MakeDirectory' $MakeDirectory
    AddMember $object 'NuGetExe' $(LocateNuGetExe)
    AddMember $object 'NuGetArgs' $(ConstructNuGetArgs)
    AddMember $object 'NugetRepositoryUrl' $NugetRepositoryUrl
    AddMember $object 'NuGetConfig' $(LocateNuGetConfig)

    # Hide all parameters
    $PSBoundParameters.GetEnumerator() | %{ set-variable -name $_.Key -Option private -ErrorAction SilentlyContinue}
    return $object
}

function private:Get-Version()
{
    return "3.0.0.0"
}

try
{
	$ErrorActionPreference = 'Stop'
	if($AnsiConsole) {. $PSScriptRoot\psmake.ansi.ps1}
    . $PSScriptRoot\psmake.core.ps1
    $Context = BuildContext

	if ($ListAvailableModules) { . $PSScriptRoot\psmake.modules.ps1; List-AvailableModules; }
	elseif ($ListModules) { . $PSScriptRoot\psmake.modules.ps1; List-Modules; }
	elseif ($AddModule) { . $PSScriptRoot\psmake.modules.ps1; Add-Module $ModuleName $ModuleVersion; }
	elseif ($UpdateAllModules) { . $PSScriptRoot\psmake.modules.ps1; Update-Modules; }
	elseif ($GetVersion) { Get-Version }
	elseif ($Scaffold) { . $PSScriptRoot\psmake.scaffold.ps1; Scaffold-Project $scaffold $(Get-Version); }
	else { Write-Host "Make..." }
}
catch [Exception]
{
	$_.Exception | format-list -force | Out-String | Write-Host -ForegroundColor 'DarkRed'
	throw
}
finally
{
	if($AnsiConsole) { remove-item function:Write-Host }
}