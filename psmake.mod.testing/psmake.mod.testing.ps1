function Define-NUnitTests
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        # Test group name. Used for display as well as naming reports. 
        [ValidateNotNullOrEmpty()]
        [Alias('Name','tgn')]
        [string]$GroupName,

        [Parameter(Mandatory=$true, Position=1)]
        # Test assembly path, where path supports * and ? wildcards.
        # It is possible to specify multiple paths.
		[ValidateNotNullOrEmpty()]
        [Alias('ta')]
		[string[]]$TestAssembly,

        [Parameter()]
        # Test report name. If not specified, a GroupName parameter would be used (spaces would be converted to underscores). 
        [AllowNull()]
        [string]$ReportName = $null,

        [Parameter()]
		# NUnit.Runners version. By default it is: 2.6.4
		[ValidateNotNullOrEmpty()]
		[ValidatePattern("^[0-9]+(\.[0-9]+){0,3}$")]
        [Alias('RunnerVersion')]
		[string]$NUnitVersion = "2.6.4"
    )

    . $PSScriptRoot\internals.ps1
    if (($ReportName -eq $null) -or ($ReportName -eq '')) { $ReportName = $GroupName -replace ' ','_' }

    Create-Object @{
        Package='NUnit.Runners';
        PackageVersion=$NUnitVersion;
        GroupName=$GroupName;
        ReportName=$ReportName;
        Assemblies=[string[]](Resolve-TestAssemblies $TestAssembly);
        Runner='tools\nunit-console.exe';
        GetRunnerArgs={
            param([PSObject]$Definition, [string]$ReportDirectory)
            return $Definition.Assemblies + "/nologo", "/noshadow", "/domain:single", "/trace=Error", "/xml:$ReportDirectory\$($Definition.ReportName).xml"
        };}
}

function Define-MbUnitTests
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true, Position=0)]
        # Test group name. Used for display as well as naming reports. 
        [ValidateNotNullOrEmpty()]
        [Alias('Name','tgn')]
        [string]$GroupName,

        [Parameter(Mandatory=$true, Position=1)]
        # Test assembly path, where path supports * and ? wildcards.
        # It is possible to specify multiple paths.
		[ValidateNotNullOrEmpty()]
        [Alias('ta')]
		[string[]]$TestAssembly,

        [Parameter()]
        # Test report name. If not specified, a GroupName parameter would be used (spaces would be converted to underscores). 
        [AllowNull()]
        [string]$ReportName = $null,
		
		[Parameter()]
		# GallioBundle version. By default it is: 3.4.14
		[ValidateNotNullOrEmpty()]
		[ValidatePattern("^[0-9]+(\.[0-9]+){0,3}$")]
		[string]$MbUnitVersion = "3.4.14"
	)

    . $PSScriptRoot\internals.ps1
    if (($ReportName -eq $null) -or ($ReportName -eq '')) { $ReportName = $GroupName -replace ' ','_' }

    Create-Object @{
        Package='GallioBundle';
        PackageVersion=$MbUnitVersion;
        GroupName=$GroupName;
        ReportName=$ReportName;
        Assemblies=[string[]](Resolve-TestAssemblies $TestAssembly);
        Runner='bin\Gallio.Echo.exe';
        GetRunnerArgs={
            param([PSObject]$Definition, [string]$ReportDirectory) 
            return $Definition.Assemblies + "/no-logo", "/rt:Xml", "/rd:$ReportDirectory", "/rnf:$($Definition.ReportName)" 
        };}
}

function Define-MsTests
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true, Position=0)]
        # Test group name. Used for display as well as naming reports. 
        [ValidateNotNullOrEmpty()]
        [Alias('Name','tgn')]
        [string]$GroupName,

        [Parameter(Mandatory=$true, Position=1)]
        # Test assembly path, where path supports * and ? wildcards.
        # It is possible to specify multiple paths.
		[ValidateNotNullOrEmpty()]
        [Alias('ta')]
		[string[]]$TestAssembly,

        [Parameter()]
        # Test report name. If not specified, a GroupName parameter would be used (spaces would be converted to underscores). 
        [AllowNull()]
        [string]$ReportName = $null,
		
		[Parameter()]
		# Visual Studio version used to find mstest.exe. The default is: 12.0
		[ValidateNotNullOrEmpty()]
		[string]$VisualStudioVersion = "12.0"
	)

    . $PSScriptRoot\internals.ps1
    if (($ReportName -eq $null) -or ($ReportName -eq '')) { $ReportName = $GroupName -replace ' ','_' }

    Create-Object @{
        Package=$null;
        PackageVersion=$null;
        GroupName=$GroupName;
        ReportName=$ReportName;
        Assemblies=[string[]](Resolve-TestAssemblies $TestAssembly);
        Runner="${env:ProgramFiles(x86)}\Microsoft Visual Studio $VisualStudioVersion\Common7\IDE\mstest.exe";
        GetRunnerArgs={
            param([PSObject]$Definition, [string]$ReportDirectory) 
            [string[]] $asms = $Definition.Assemblies | %{ "/testcontainer:$_"}
            return ($asms + "/nologo", "/resultsfile:$ReportDirectory\$($Definition.ReportName).trx") 
        };}
}

function Run-Tests
{
    [CmdletBinding()]
	param (
		[Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="coverage")]
		[Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="test")]
		# An array of test definitions.
		[ValidateNotNullOrEmpty()]
		[PSObject[]]$TestDefinition,
		
		[Parameter(Mandatory=$true,ParameterSetName="coverage")]
		# Run tests with OpenCover to determine coverage level
		[switch]$Cover,
		
		[Parameter(Mandatory=$true,ParameterSetName="coverage")]
		# OpenCover code filter (used for -filter param), like: +[Company.Project.*]* -[*Tests*]*
		[ValidateNotNullOrEmpty()]
		[string]$CodeFilter,
				
		[Parameter(ParameterSetName="coverage")]
		# OpenCover test filter (used for -coverbytest param), like: *.Tests.Unit.dll
		[ValidateNotNullOrEmpty()]
		[string]$TestFilter="*Tests.dll",
		
		[Parameter()]
		# Reports directory. By default it is 'reports'
		[ValidateNotNullOrEmpty()]
		[string]$ReportDirectory = "reports",

        [Parameter()]
		# Delete reports directory before execution. By default it is: $false
		[switch]$EraseReportDirectory = $false,
		
		[Parameter(ParameterSetName="coverage")]
		# OpenCover version. By default it is: 4.5.2506
		[ValidateNotNullOrEmpty()]
		[ValidatePattern("^[0-9]+(\.[0-9]+){0,3}$")]
		[string]$OpenCoverVersion="4.5.2506"
    )
    begin
    {
        . $PSScriptRoot\internals.ps1
        Prepare-ReportDirectory $ReportDirectory $EraseReportDirectory
        
        $coverageReports = @()
    }

    process
    {
        Write-Status "Testing $($_.GroupName)"
        $runnerArgs = & $_.GetRunnerArgs $_ $ReportDirectory
        if($_.Package -ne $null)
        { 
            $runnerPath = Fetch-Package $_.Package $_.PackageVersion
            $runner = "$runnerPath\$($_.Runner)"
        }
        else { $runner = $_.Runner }

        if (! $Cover)
	    { 
		    Write-ShortStatus "Running tests"
		    call $runner -args $runnerArgs
	    }
        else
        {	
	        $CoverageReport = "$ReportDirectory\$($_.ReportName)_coverage.xml"
	        Run-OpenCover -OpenCoverVersion $OpenCoverVersion -Runner $runner -RunnerArgs $runnerArgs -CodeFilter $CodeFilter -TestFilter $TestFilter -Output $CoverageReport

            $coverageReports += $CoverageReport
        }
	
    }

    end
    {
        if($coverageReports.Length -gt 0) { Create-Object @{ ReportDirectory=$ReportDirectory; CoverageReports=$coverageReports; } }
    }
}

function Generate-CoverageSummary
{
    [CmdletBinding()]
	param (
		[Parameter(Mandatory=$true,ParameterSetName="standard")]
		# Path to coverage reports.
		[ValidateNotNullOrEmpty()]
		[string[]]$CoverageReports,

        [Parameter(ParameterSetName="standard")]
		# Report directory. Default: reports
		[ValidateNotNullOrEmpty()]
		[string]$ReportDirectory = 'reports',

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName="reportInput")]
        # Run-Tests result.
        [ValidateNotNull()]
        [PSObject]$TestResult,

        [Parameter()]
		# ReportGenerator version. By default it is: 1.9.1.0
		[ValidateNotNullOrEmpty()]
		[ValidatePattern("^[0-9]+(\.[0-9]+){0,3}$")]
		[string]$ReportGeneratorVersion="1.9.1.0"
    )

	Write-ShortStatus "Preparing ReportGenerator"
	$reportGenPath = Fetch-Package "ReportGenerator" $ReportGeneratorVersion
	$ReportGeneratorPath="$reportGenPath\ReportGenerator.exe"
	
    if ($TestResult -ne $null)
    {
        $CoverageReports = $TestResult.CoverageReports
        $ReportDirectory = $TestResult.ReportDirectory
    }

	Write-ShortStatus "Generating coverage reports"
    $reports = $CoverageReports -join ';'
	call "$ReportGeneratorPath" "-reporttypes:html,xmlsummary" "-verbosity:error" "-reports:$reports" "-targetdir:$ReportDirectory\summary"
    Write-Output "$ReportDirectory\summary\Summary.xml"
}

function Check-AcceptableCoverage
{
    [CmdletBinding()]
	param (
		[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
		# Path to coverage summary report (generated by Generate-CoverageSummary function).
		[ValidateNotNullOrEmpty()]
		[string]$SummaryReport,

        [Parameter(Mandatory=$true)]
		# Minimal acceptable coverage
		[ValidateRange(0,100)] 
		[int]$AcceptableCoverage
    )
	Write-ShortStatus "Validating code coverage being at least $AcceptableCoverage%"

	[xml]$coverage = Get-Content $SummaryReport
	$actualCoverage = [double]($coverage.CoverageReport.Summary.Coverage -replace '%','')
	Write-Host "Coverage is $actualCoverage%"
	if($actualCoverage -lt $AcceptableCoverage) {
		throw "Coverage $($actualCoverage)% is below threshold $($AcceptableCoverage)%"
	}
}