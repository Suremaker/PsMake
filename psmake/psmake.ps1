[CmdletBinding(DefaultParameterSetName="Make")]
param (
	[Parameter(Mandatory=$true, ParameterSetName="ListAvailableModules", HelpMessage="Lists all available modules.")]
	[Alias('lam')]
	[switch] $ListAvailableModules,

	[Parameter(Mandatory=$true, ParameterSetName="ListModules", HelpMessage="Lists currently installed modules.")]
	[Alias('lm')]
	[switch] $ListModules,

	[Parameter(Mandatory=$true, ParameterSetName="AddModule", HelpMessage="Adds a new module to Modules.ps1.")]
	[Alias('am')]
	[switch] $AddModule,

	[Parameter(Mandatory=$true, ParameterSetName="UpdateAllModules", HelpMessage="Update all modules from Modules.ps1 to the newest available version.")]
	[Alias('uam')]
	[switch] $UpdateAllModules,

	[Parameter(Mandatory=$true, ParameterSetName="Version", HelpMessage="Prints psmake version")]
	[switch] $GetVersion,
	
	
	[Parameter(Mandatory=$true, ParameterSetName="Scaffold", HelpMessage="Generates a scaffold psmake setup.")]
	[ValidateSet('build-test')]
	[string] $Scaffold,
	
	[Parameter(Mandatory=$true, ParameterSetName="AddModule", HelpMessage="Module name to add.")]
	[Alias('mn','Name')]
	[ValidateNotNullOrEmpty()]
	[string] $ModuleName,

	[Parameter(ParameterSetName="AddModule", HelpMessage="Module version to add. If not specified, the newest one would be added.")]
	[Alias('mv','Version')]
	[AllowNull()]
	[ValidatePattern("^[0-9]+(\.[0-9]+){0,3}$")]
	[string] $ModuleVersion = $null,

	[Parameter(HelpMessage="Make files directory. A directory where Makefile.ps1 and other files should be placed.")]
	[Alias('md')]
	[ValidateNotNullOrEmpty()]
	[string] $MakeDirectory = ".",

	[Parameter(HelpMessage="NuGet source to use for fetching modules and packages. It can have semicolon separated urls/paths. If not specified, NuGet.exe would be called without source parameter.")]
	[Alias('Source','nru')]
	[AllowNull()]
	[string] $NugetRepositoryUrl,
	
	[Parameter(HelpMessage="NuGet.exe path like: .nuget\NuGet.exe. If not specified, NuGet.exe would be expected to be on PATH environment variable.")]
	[AllowNull()]
	[string] $NuGetExe,
	
	[Parameter(HelpMessage="NuGet.Config path like: .nuget\NuGet.Config. If not specified, NuGet.exe would be executed without config file.")]
	[AllowNull()]
	[string] $NuGetConfig,
	
	[Parameter(HelpMessage="Makes Write-Host to write ANSI escaped colors - use only if script is running on terminal supporting ANSI escape sequences.")]
	[Alias('ansi','ac')]
	[switch] $AnsiConsole = $false,
	
	[Parameter(ParameterSetName="Make",ValueFromRemainingArguments=$true, HelpMessage="Additional make parameters that would be available for make steps via `$Params variable.`nExpected format:`nkey1:value1 - where `$Params.key1 would be equal value1`nkey2 - where `$Param.key2 would be equal `$true")]
	[Alias('ap')]
	[string[]] $AdditionalParams
)

# Hide all parameters
$PSBoundParameters.GetEnumerator() | %{ set-variable -name $_.Key -Option private -ErrorAction SilentlyContinue}

if ($ListAvailableModules) { Write-Host "Listing available modules..." }
elseif ($ListModules) { Write-Host "Listing modules..." }
elseif ($AddModule) { Write-Host "Adding module $ModuleName=$ModuleVersion..." }
elseif ($UpdateAllModules) { Write-Host "Updating modules..." }
elseif ($GetVersion) { Write-Host "Returning version..." }
elseif ($Scaffold) { Write-Host "Scaffolding..." }
else { Write-Host "Make..." }