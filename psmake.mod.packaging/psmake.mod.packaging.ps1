<#
.SYNOPSIS 
Packages Visual Studio projects (like .csproj etc.)

.DESCRIPTION
Packages Visual Studio projects to .nupkg package.
By default, all project references are packaged as nuget references (nuget.exe is called with .csproj file and -IncludeReferencedProjects flag).

.EXAMPLE
PS> Package-VSProject -Project "c:\solution\project.csproj"
#>
function Package-VSProject
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        # Visual Studio project path
        [ValidateNotNullOrEmpty()]
        [string]$Project,

        [Parameter()]
        # Project configuration. Default: Release
        [ValidateNotNullOrEmpty()]
        [string]$Configuration = "Release",

        [Parameter()]
        # Include referenced projects. Default: true
        [ValidateNotNull()]
        [bool]$IncludeReferencedProjects = $true,

        [Parameter()]
        # Generate symbol package. Default: false
        [ValidateNotNull()]
        [bool]$Symbols = $false,
		
		[Parameter()]
		# Overwrite package version with specified value. Default: null, which means no.
		[string]$Version = $null,
		
		[Parameter()]
		# Output directory. Default: .
		[ValidateNotNullOrEmpty()]
		[string]$Output = '.'
    )
	process {
		$arguments = @("pack",$Project,"-Prop","Configuration=$Configuration","-NonInteractive","-Output",$Output)
		if ($IncludeReferencedProjects) { $arguments += "-IncludeReferencedProjects"}
		if ($Symbols) { $arguments += "-Symbols" }
		if ($Version) { $arguments += "-Version"; $arguments += $Version; }
		
		Write-ShortStatus "Packaging: $Project..."
		call $Context.NuGetExe @arguments
	}
}

<#
.SYNOPSIS 
Packages .nuspec file.

.DESCRIPTION
Packages .nuspec to .nupkg package.
This method is dedicated for creation of deployable packages, so -NoPackageAnalysis is set by default and nuget.exe is called with .nuspec file.

.EXAMPLE
PS> Package-DeployableNuSpec -Package "c:\solution\project.nuspec"
#>
function Package-DeployableNuSpec
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        # NuSpec file path
        [ValidateNotNullOrEmpty()]
        [string]$Package,
		
		[Parameter()]
		# Overwrite package version with specified value. Default: null, which means no.
		[string]$Version = $null,
		
		[Parameter()]
		# Output directory. Default: .
		[ValidateNotNullOrEmpty()]
		[string]$Output = '.',
		
		[Parameter()]
        # No package analysis. Default: true
        [ValidateNotNull()]
        [bool]$NoPackageAnalysis = $true,
		
		[Parameter()]
        # No default excluded. Default: false
        [ValidateNotNull()]
        [bool]$NoDefaultExcludes = $false
    )
	process {
		$arguments = "pack",$Package,"-NonInteractive","-Output",$Output
		if ($NoPackageAnalysis) { $arguments += "-NoPackageAnalysis"}
		if ($NoDefaultExcludes) { $arguments += "-NoDefaultExcludes"}
		if ($Version) { $arguments += "-Version"; $arguments += $Version; }
		
		Write-ShortStatus "Packaging: $Package..."
		call $Context.NuGetExe @arguments
	}
}

<#
.SYNOPSIS 
Finds Visual Studio projects suitable for packaging.

.DESCRIPTION
Finds Visual Studio projects suitable for packaging.
This method scans a specified directory (see -Path parameter) and its sub-directories and returns paths to all projects that have corresponding .nuspec files of the same name and located in the same directory.

.EXAMPLE
PS> Find-VSProjectsForPackaging -Path 'c:\solution' | Package-VSProject

Scans 'c:\solution' directory and sub-directories and packages all .csproj projects that have corresponding .nuspec files.

.EXAMPLE
PS> Find-VSProjectsForPackaging -Path 'c:\solution' -Exclude '*Host.csproj' | Package-VSProject

Scans 'c:\solution' directory and sub-directories and packages all .csproj projects that have corresponding .nuspec files, excluding *Host projects.
#>
function Find-VSProjectsForPackaging
{
    [CmdletBinding()]
    param(
        [Parameter()]
        # A path to start search. Default: .
        [ValidateNotNullOrEmpty()]
        [string]$Path = '.',

        [Parameter()]
        # Projects to find. Default: *.csproj
        [ValidateNotNullOrEmpty()]
        [string]$Filter = '*.csproj',
		
		[Parameter()]
        # Projects to exclude. Default: @()
        [ValidateNotNullOrEmpty()]
        [string[]]$Exclude = @()
    )
	return Get-ChildItem -Path $Path -Filter $Filter -Recurse -Exclude $Exclude `
		| Where-Object { Test-Path ($_.fullname -replace $_.Extension,'.nuspec')} `
		| %{$_.fullname }
}

<#
.SYNOPSIS 
Finds .nuspec files.

.DESCRIPTION
Finds .nuspec files.
This method scans a specified directory (see -Path parameter) and its sub-directories and returns paths to all matching .nuspec files.

.EXAMPLE
PS> Find-NuSpecFiles -Path 'c:\solution' | Package-DeployableNuSpec

Scans 'c:\solution' directory and sub-directories and packages all .nuspec files.

.EXAMPLE
PS> Find-NuSpecFiles -Path 'c:\solution' -Filter '*-deploy.nuspec' | Package-DeployableNuSpec

Scans 'c:\solution' directory and sub-directories and packages all .nuspec files that have -deploy suffix.
#>
function Find-NuSpecFiles
{
    [CmdletBinding()]
    param(
        [Parameter()]
        # A path to start search. Default: .
        [ValidateNotNullOrEmpty()]
        [string]$Path = '.',

        [Parameter()]
        # NuSpec files to find. Default: *.nuspec
        [ValidateNotNullOrEmpty()]
        [string]$Filter = '*.nuspec',
		
		[Parameter()]
        # NuSpec to exclude. Default: @()
        [ValidateNotNullOrEmpty()]
        [string[]]$Exclude = @()
    )
	return Get-ChildItem -Path $Path -Filter $Filter -Recurse -Exclude $Exclude `
		| %{$_.fullname }
}