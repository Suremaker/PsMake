<#
.SYNOPSIS 
Replaces version string in a specified file.

.DESCRIPTION
Replaces version string in a specified file.
It allows to replace a version string occurrences in given file to a version specified by Version parameter

.EXAMPLE
PS> Update-InFile 'project\AssemblyVersion.cs' '1.0.0.1' 'Version("%")'"
#>
function Update-VersionInFile
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        # File path. 
        [ValidateNotNullOrEmpty()]
        [string]$File,

        [Parameter(Mandatory=$true, Position=1)]
        # New version
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^[0-9]+(\.[0-9]+){0,3}$")]
        [string]$Version,

        [Parameter(Mandatory=$true, Position=2)]
        # Matchings representing patterns with version string, where % represents version itself.
        # Example: 'Version("%")'
        [ValidateNotNullOrEmpty()]
        [string[]]$matchings
    )

    Write-ShortStatus "Updating $File with $Version..."
    $content = Get-Content $File -Encoding UTF8
    foreach($match in $matchings)
    {
        $from = [Regex]::Escape($match) -replace '%','[0-9]+(\.[0-9]+){0,3}'
        $to = $match -replace '%',$Version

        $content = $content -replace $from,$to
    }
    Set-Content $File -Value $content -Encoding UTF8
}

<#
.SYNOPSIS 
Replaces version string all specified assembly info files located in specified solution directory.

.DESCRIPTION
Replaces version string all specified assembly info files located in specified solution directory.
If no AssemblyInfoFileNames specified then 'AssemblyInfo.cs' will be used.

.EXAMPLE
PS> Update-VersionInAssemblyInfo '1.0.0.22' 'slnDir'" ('AssemblyInfo.cs')
#>
function Update-VersionInAssemblyInfo
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        # Version to set to
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^[0-9]+(\.[0-9]+){0,3}$")]
        [string]$Version,
        
        [Parameter()]
        # Solution directory
        [string]$SolutionDirectory = ".",
		
		[Parameter()]
        # Assembly info file names
        [string[]]$AssemblyInfoFileNames = ("AssemblyInfo.cs")
    ) 
    function Update-SourceVersion ($version)
    {
        foreach ($o in $input) 
        {
            Update-VersionInFile $o.FullName $version 'Version("%")'
        }
    }

    function Update-AllAssemblyInfoFiles ( $version )
    {
        get-childitem -Path $SolutionDirectory -recurse |? {$_.Name -in $AssemblyInfoFileNames} | Update-SourceVersion $Version
    }

    Write-Status "Updating all AssemblyInfo.cs version to $version in $SolutionDirectory directory"
    Update-AllAssemblyInfoFiles $Version;
}