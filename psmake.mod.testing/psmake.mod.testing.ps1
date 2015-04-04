function script:Prepare-ReportDirectory($ReportDirectory, $erase)
{
	if ($EraseReportDirectory) 
	{
		Write-ShortStatus "Cleaning $ReportDirectory..."; 
		Remove-Item $ReportDirectory -Force -Recurse -ErrorAction SilentlyContinue
	}
	mkdir $ReportDirectory -ErrorAction SilentlyContinue | Out-Null
}

function Run-OpenCover($OpenCoverVersion, $Runner, $RunnerArgs, $CodeFilter, $TestFilter, $Output)
{
	Write-ShortStatus "Preparing OpenCover"
	$openCoverPath = Fetch-Package "OpenCover" $OpenCoverVersion
	$OpenCoverConsole="$openCoverPath\OpenCover.Console.exe"

	Write-ShortStatus "Running tests with OpenCover"
	call "$OpenCoverConsole" "-log:Error" "-showunvisited" "-register:user" "-target:$Runner"  "-filter:$CodeFilter" "-output:$Output" "-returntargetcode" "-coverbytest:$TestFilter" "-targetargs:$RunnerArgs"
}

function Generate-CoverageSummary
{
    [CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)]
		# Path to coverage report.
		[ValidateNotNullOrEmpty()]
		[string[]]$CoverageReports,

        [Parameter()]
		# Report directory. Default: reports
		[ValidateNotNullOrEmpty()]
		[string]$ReportDirectory = 'reports',

        [Parameter()]
		# ReportGenerator version. By default it is: 1.9.1.0
		[ValidateNotNullOrEmpty()]
		[ValidatePattern("^[0-9]+(\.[0-9]+){0,3}$")]
		[string]$ReportGeneratorVersion="1.9.1.0"
    )

	Write-ShortStatus "Preparing ReportGenerator"
	$reportGenPath = Fetch-Package "ReportGenerator" $ReportGeneratorVersion
	$ReportGeneratorPath="$reportGenPath\ReportGenerator.exe"
	
	Write-ShortStatus "Generating coverage reports"
    $reports = $CoverageReports -join ';'
	call "$ReportGeneratorPath" "-reporttypes:html,xmlsummary" "-verbosity:error" "-reports:$reports" "-targetdir:$ReportDirectory\summary"
}

function Check-AcceptableCoverage
{
    [CmdletBinding()]
	param (
		[Parameter(Mandatory=$true)]
		# Path to coverage summary report.
		[ValidateNotNullOrEmpty()]
		[string]$SummaryReport,

        [Parameter(Mandatory=$true)]
		# Minimal acceptable coverage
		[ValidateRange(0,100)] 
		[int]$AcceptableCoverage
    )
	Write-ShortStatus "Validating code coverage being at least $AcceptableCoverage percent"

	[xml]$coverage = Get-Content $SummaryReport
	$actualCoverage = [double]($coverage.CoverageReport.Summary.Coverage -replace '%','')
	Write-Host "Coverage is $actualCoverage"
	if($actualCoverage -lt $AcceptableCoverage) {
		throw "Coverage $($actualCoverage) is below threshold $($AcceptableCoverage)"
	}
}

function script:Find-TestAssemblies ([string[]]$TestAssemblies)
{
	$results = @()
    $includes = @()
    $results += $TestAssemblies | Where-Object {$_.IndexOfAny('*?'.ToCharArray()) -lt 0}
    $includes += $TestAssemblies | Where-Object {$_.IndexOfAny('*?'.ToCharArray()) -ge 0} | %{ '^'+ ($_ -replace '\\','\\' -replace '\.','\.' -replace '\?','.' -replace '\*','.*') +'$' }

    if($includes.Length -gt 0) 
    { 
        Write-ShortStatus "Scanning for test assemblies"
        $pattern = $includes -join '|'
        $results += Get-ChildItem -Recurse | Where-Object { $_.FullName -match $pattern } | %{$_.FullName}        
        $results | Write-Host
    }

    return $results -join ','
}

function Run-NUnitTests()
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true,ParameterSetName="coverageCheck")]
		[Parameter(Mandatory=$true,ParameterSetName="coverage")]
		[Parameter(Mandatory=$true,ParameterSetName="test")]
		# An array of test assemblies paths, where path supports * and ? wildcards.
		[ValidateNotNullOrEmpty()]
		[string[]]$TestAssemblies,
		
		[Parameter(Mandatory=$true,ParameterSetName="coverageCheck")]
		[Parameter(Mandatory=$true,ParameterSetName="coverage")]
		# Run tests with OpenCover to determine coverage level
		[switch]$Cover,
		
		[Parameter(ParameterSetName="coverage")]
		# Skips coverage summary generation. If set, ReportGenerator will not be used to generate html and xmlsummary coverage reports.
		[switch]$NoCoverageSummary=$false,
		
		[Parameter(Mandatory=$true,ParameterSetName="coverage")]
        [Parameter(Mandatory=$true,ParameterSetName="coverageCheck")]
		# OpenCover code filter (used for -filter param), like: +[Company.Project.*]* -[*Tests*]*
		[ValidateNotNullOrEmpty()]
		[string]$CodeFilter,
				
		[Parameter(Mandatory=$true,ParameterSetName="coverageCheck")]
		# Minimal acceptable coverage
		[ValidateRange(0,100)] 
		[int]$AcceptableCoverage,
		
		[Parameter(ParameterSetName="coverageCheck")]
		[Parameter(ParameterSetName="coverage")]
		# OpenCover test filter (used for -coverbytest param), like: *.Tests.Unit.dll
		[ValidateNotNullOrEmpty()]
		[string]$TestFilter="*Tests.dll",
		
		[Parameter()]
		# Reports directory. By default it is 'reports'
		[ValidateNotNullOrEmpty()]
		[string]$ReportDirectory = "reports",
		
		[Parameter()]
		# Report name. It would be used by NUnitRunner as well as OpenCover and ReportGenerator. By default it is: test-results
		[ValidateNotNullOrEmpty()]
		[string]$ReportName = "test-results",
		
		[Parameter()]
		# Delete reports directory before execution. By default it is: $false
		[switch]$EraseReportDirectory = $false,
		
		[Parameter()]
		# NUnit.Runners version. By default it is: 2.6.3
		[ValidateNotNullOrEmpty()]
		[ValidatePattern("^[0-9]+(\.[0-9]+){0,3}$")]
		[string]$NUnitVersion = "2.6.3",
		
		[Parameter(ParameterSetName="coverageCheck")]
		[Parameter(ParameterSetName="coverage")]
		# OpenCover version. By default it is: 4.5.2506
		[ValidateNotNullOrEmpty()]
		[ValidatePattern("^[0-9]+(\.[0-9]+){0,3}$")]
		[string]$OpenCoverVersion="4.5.2506",
		
		[Parameter(ParameterSetName="coverageCheck")]
		[Parameter(ParameterSetName="coverage")]
		# ReportGenerator version. By default it is: 1.9.1.0
		[ValidateNotNullOrEmpty()]
		[ValidatePattern("^[0-9]+(\.[0-9]+){0,3}$")]
		[string]$ReportGeneratorVersion="1.9.1.0"
	)

	Write-Status "Executing tests for: $TestAssemblies"

	Prepare-ReportDirectory $ReportDirectory $EraseReportDirectory
	$assemblies = Find-TestAssemblies $TestAssemblies
	
	Write-ShortStatus "Preparing NUnit Runner"
	$nunitPath = Fetch-Package "NUnit.Runners" $NUnitVersion
	$NUnitConsole="$nunitPath\tools\nunit-console.exe"
	$NUnitArgs="$assemblies /nologo /noshadow /domain:single /trace=Error /xml:$ReportDirectory/$ReportName.xml"
	
	if (! $Cover)
	{ 
		Write-ShortStatus "Running tests"
		call $NUnitConsole $NUnitArgs
		return
	}
	
	$CoverageReport = "$ReportDirectory\$($ReportName)_coverage.xml"

	Run-OpenCover -OpenCoverVersion $OpenCoverVersion -Runner $NunitConsole -RunnerArgs $NUnitArgs -CodeFilter $CodeFilter -TestFilter $TestFilter -Output $CoverageReport
	
	if ($NoCoverageSummary) { return }

	Generate-CoverageSummary -ReportGeneratorVersion $ReportGeneratorVersion -CoverageReports $CoverageReport -ReportDirectory $ReportDirectory 
	
	if ($AcceptableCoverage -gt 0) { Check-AcceptableCoverage -SummaryReport "$ReportDirectory\summary\summary.xml" -AcceptableCoverage $AcceptableCoverage }	
}

function Run-MbUnitTests()
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true,ParameterSetName="coverageCheck")]
		[Parameter(Mandatory=$true,ParameterSetName="coverage")]
		[Parameter(Mandatory=$true,ParameterSetName="test")]
		# An array of test assemblies paths, where path supports * and ? wildcards.
		[ValidateNotNullOrEmpty()]
		[string[]]$TestAssemblies,
		
		[Parameter(Mandatory=$true,ParameterSetName="coverageCheck")]
		[Parameter(Mandatory=$true,ParameterSetName="coverage")]
		# Run tests with OpenCover to determine coverage level
		[switch]$Cover,
		
		[Parameter(ParameterSetName="coverage")]
		# Skips coverage summary generation. If set, ReportGenerator will not be used to generate html and xmlsummary coverage reports.
		[switch]$NoCoverageSummary=$false,
		
		[Parameter(Mandatory=$true,ParameterSetName="coverage")]
        [Parameter(Mandatory=$true,ParameterSetName="coverageCheck")]
		# OpenCover code filter (used for -filter param), like: +[Company.Project.*]* -[*Tests*]*
		[ValidateNotNullOrEmpty()]
		[string]$CodeFilter,
				
		[Parameter(Mandatory=$true,ParameterSetName="coverageCheck")]
		# Minimal acceptable coverage
		[ValidateRange(0,100)] 
		[int]$AcceptableCoverage,
		
		[Parameter(ParameterSetName="coverageCheck")]
		[Parameter(ParameterSetName="coverage")]
		# OpenCover test filter (used for -coverbytest param), like: *.Tests.Unit.dll
		[ValidateNotNullOrEmpty()]
		[string]$TestFilter="*Tests.dll",
		
		[Parameter()]
		# Reports directory. By default it is 'reports'
		[ValidateNotNullOrEmpty()]
		[string]$ReportDirectory = "reports",
		
		[Parameter()]
		# Report name. It would be used by NUnitRunner as well as OpenCover and ReportGenerator. By default it is: test-results
		[ValidateNotNullOrEmpty()]
		[string]$ReportName = "test-results",
		
		[Parameter()]
		# Delete reports directory before execution. By default it is: $false
		[switch]$EraseReportDirectory = $false,
		
		[Parameter()]
		# GallioBundle version. By default it is: 2.6.3
		[ValidateNotNullOrEmpty()]
		[ValidatePattern("^[0-9]+(\.[0-9]+){0,3}$")]
		[string]$MbUnitVersion = "3.4.14.0",
		
		[Parameter(ParameterSetName="coverageCheck")]
		[Parameter(ParameterSetName="coverage")]
		# OpenCover version. By default it is: 4.5.2506
		[ValidateNotNullOrEmpty()]
		[ValidatePattern("^[0-9]+(\.[0-9]+){0,3}$")]
		[string]$OpenCoverVersion="4.5.2506",
		
		[Parameter(ParameterSetName="coverageCheck")]
		[Parameter(ParameterSetName="coverage")]
		# ReportGenerator version. By default it is: 1.9.1.0
		[ValidateNotNullOrEmpty()]
		[ValidatePattern("^[0-9]+(\.[0-9]+){0,3}$")]
		[string]$ReportGeneratorVersion="1.9.1.0"
	)

	Write-Status "Executing tests for: $TestAssemblies"

	Prepare-ReportDirectory $ReportDirectory $EraseReportDirectory
	$assemblies = Find-TestAssemblies $TestAssemblies
	
	$runnerPath = Fetch-Package "GallioBundle" $MbUnitVersion
	$runnerConsole="$runnerPath\bin\Gallio.Echo.exe"
	$runnerArgs="$assemblies /no-logo /rt:Xml /rd:$ReportDirectory /rnf:$ReportName"
	
	if (! $Cover)
	{ 
		Write-ShortStatus "Running tests"
		call $runnerConsole $runnerArgs
		return
	}
	
	$CoverageReport = "$ReportDirectory\$($ReportName)_coverage.xml"

	Run-OpenCover -OpenCoverVersion $OpenCoverVersion -Runner $runnerConsole -RunnerArgs $runnerArgs -CodeFilter $CodeFilter -TestFilter $TestFilter -Output $CoverageReport
	
	if ($NoCoverageSummary) { return }

	Generate-CoverageSummary -ReportGeneratorVersion $ReportGeneratorVersion -CoverageReports $CoverageReport -ReportDirectory $ReportDirectory 
	
	if ($AcceptableCoverage -gt 0) { Check-AcceptableCoverage -SummaryReport "$ReportDirectory\summary\summary.xml" -AcceptableCoverage $AcceptableCoverage }	
}

function Run-MsTests()
{
	[CmdletBinding()]
	param (
		[Parameter(Mandatory=$true,ParameterSetName="coverageCheck")]
		[Parameter(Mandatory=$true,ParameterSetName="coverage")]
		[Parameter(Mandatory=$true,ParameterSetName="test")]
		# An array of test assemblies paths, where path supports * and ? wildcards.
		[ValidateNotNullOrEmpty()]
		[string[]]$TestAssemblies,
		
		[Parameter(Mandatory=$true,ParameterSetName="coverageCheck")]
		[Parameter(Mandatory=$true,ParameterSetName="coverage")]
		# Run tests with OpenCover to determine coverage level
		[switch]$Cover,
		
		[Parameter(ParameterSetName="coverage")]
		# Skips coverage summary generation. If set, ReportGenerator will not be used to generate html and xmlsummary coverage reports.
		[switch]$NoCoverageSummary=$false,
		
		[Parameter(Mandatory=$true,ParameterSetName="coverage")]
        [Parameter(Mandatory=$true,ParameterSetName="coverageCheck")]
		# OpenCover code filter (used for -filter param), like: +[Company.Project.*]* -[*Tests*]*
		[ValidateNotNullOrEmpty()]
		[string]$CodeFilter,
				
		[Parameter(Mandatory=$true,ParameterSetName="coverageCheck")]
		# Minimal acceptable coverage
		[ValidateRange(0,100)] 
		[int]$AcceptableCoverage,
		
		[Parameter(ParameterSetName="coverageCheck")]
		[Parameter(ParameterSetName="coverage")]
		# OpenCover test filter (used for -coverbytest param), like: *.Tests.Unit.dll
		[ValidateNotNullOrEmpty()]
		[string]$TestFilter="*Tests.dll",
		
		[Parameter()]
		# Reports directory. By default it is 'reports'
		[ValidateNotNullOrEmpty()]
		[string]$ReportDirectory = "reports",
		
		[Parameter()]
		# Report name. It would be used by NUnitRunner as well as OpenCover and ReportGenerator. By default it is: test-results
		[ValidateNotNullOrEmpty()]
		[string]$ReportName = "test-results",
		
		[Parameter()]
		# Delete reports directory before execution. By default it is: $false
		[switch]$EraseReportDirectory = $false,
		
		[Parameter()]
		# Visual Studio version used to find mstest.exe. The default is: 12.0
		[ValidateNotNullOrEmpty()]
		[string]$VisualStudioVersion = "12.0",
		
		[Parameter(ParameterSetName="coverageCheck")]
		[Parameter(ParameterSetName="coverage")]
		# OpenCover version. By default it is: 4.5.2506
		[ValidateNotNullOrEmpty()]
		[ValidatePattern("^[0-9]+(\.[0-9]+){0,3}$")]
		[string]$OpenCoverVersion="4.5.2506",
		
		[Parameter(ParameterSetName="coverageCheck")]
		[Parameter(ParameterSetName="coverage")]
		# ReportGenerator version. By default it is: 1.9.1.0
		[ValidateNotNullOrEmpty()]
		[ValidatePattern("^[0-9]+(\.[0-9]+){0,3}$")]
		[string]$ReportGeneratorVersion="1.9.1.0"
	)

	Write-Status "Executing tests for: $TestAssemblies"

	Prepare-ReportDirectory $ReportDirectory $EraseReportDirectory
	$assemblies = Find-TestAssemblies $TestAssemblies
	
	$runnerConsole="${env:ProgramFiles(x86)}\Microsoft Visual Studio $VisualStudioVersion\Common7\IDE\mstest.exe"
	$runnerArgs="/testcontainer:$assemblies /nologo"
	
	if (! $Cover)
	{ 
		Write-ShortStatus "Running tests"
		call $runnerConsole $runnerArgs
		return
	}
	
	$CoverageReport = "$ReportDirectory\$($ReportName)_coverage.xml"

	Run-OpenCover -OpenCoverVersion $OpenCoverVersion -Runner $runnerConsole -RunnerArgs $runnerArgs -CodeFilter $CodeFilter -TestFilter $TestFilter -Output $CoverageReport
	
	if ($NoCoverageSummary) { return }

	Generate-CoverageSummary -ReportGeneratorVersion $ReportGeneratorVersion -CoverageReports $CoverageReport -ReportDirectory $ReportDirectory 
	
	if ($AcceptableCoverage -gt 0) { Check-AcceptableCoverage -SummaryReport "$ReportDirectory\summary\summary.xml" -AcceptableCoverage $AcceptableCoverage }	
}