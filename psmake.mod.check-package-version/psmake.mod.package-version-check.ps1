<#
.SYNOPSIS 
Ensures that all packages.config files contains the same NuGet package version.

.DESCRIPTION
Ensures that all packages.config files contains the same NuGet package version.
This method scans a specified directory (see -Path parameter) and its sub-directories and checks that the same version of the NuGet package is used in all packages.config files.

.EXAMPLE
PS> Ensure-SamePackageVersionIsUsed -Path 'c:\solution'

Scans 'c:\solution' directory and sub-directories and checks that in all found packages.config files NuGet packages with the same id have the same version and targetFramework.

.EXAMPLE
PS> Ensure-SamePackageVersionIsUsed -Path 'c:\solution' -IgnoreTargetFramework

Scans 'c:\solution' directory and sub-directories and checks that in all found packages.config files NuGet packages with the same id have the same version and targetFramework.

.EXAMPLE
PS> Ensure-SamePackageVersionIsUsed -Path 'c:\solution' -Exceptions ('log4net')

Scans 'c:\solution' directory and sub-directories and checks that in all found packages.config files NuGet packages with the same id have the same version and targetFramework allowing different log4net package versions.
#>
function Ensure-SamePackageVersionIsUsed
{
    [CmdletBinding()]
    param(
        [Parameter()]
        # A path to start search. Default: .
        [ValidateNotNullOrEmpty()]
        [string]$Path = '.',

        [Parameter()]
        # Should trgetFramework difference be ignored. Default: $false
        [ValidateNotNullOrEmpty()]
        [switch]$IgnoreTargetFramework = $false,

        [Parameter()]
        # Package names to allow different package versions. Default: @()
        [ValidateNotNullOrEmpty()]
        [string[]]$Exceptions = @()
    )

    [array]$packages = @()
    [array]$errorPackages = @()

    Get-ChildItem -Path $Path -Filter 'packages.config' -Recurse |
    ForEach{
        [xml]$packageConfig = Get-Content $_.FullName
        $packages += $packageConfig.Packages.Package
    } 

    $packages = $packages | Sort-Object -Property @{Expression={getNuGetPackageKeyForSorting -package:$_ -ignoreTargetFramework:$IgnoreTargetFramework}} -Unique |
                            Group-Object id |
                            Where {$_.Count -gt 1 -and $exceptions -notcontains $_.Name}
    
    $packages | Format-Table -Wrap -AutoSize `
                             -Property @{Expression={ $_.Name}; Label="Package Name" },
                                       @{Expression={ ($_.Group | %{getNuGetPackageVersion -package:$_ -ignoreTargetFramework:$IgnoreTargetFramework}) -Join ', '}; Label="Package Version" } | Write-Output

    if($packages.Length -gt 0)
    {
        Write-Error "Different versions of the same NuGet package are used across the solution. Please use the same version or add package to the list of Exceptions."
    }
}

function getNuGetPackageKeyForSorting([array] $package, [bool]$ignoreTargetFramework)
{
    if($ignoreTargetFramework)
    {
        return $package.id + $package.version
    }
    else
    {
        return $package.id + $package.version + $package.targetFramework
    }
}

function getNuGetPackageVersion([array]$package, [bool]$ignoreTargetFramework)
{
    if($ignoreTargetFramework)
    {
        return $package.version
    }
    else
    {
        return $package.version + ' [' +$package.targetFramework + ']'
    }
}