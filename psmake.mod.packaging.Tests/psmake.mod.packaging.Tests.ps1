$here = (Split-Path -Parent $MyInvocation.MyCommand.Path).Replace(".Tests", "")
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\..\psmake\ext\psmake.core.ps1"
. "$here\$sut"

<# Disable Write-Host in tested code #>
function Write-Host
{
    param(
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromRemainingArguments=$true)]
        ${Object},
        [switch]${NoNewline},
        ${Separator},
        ${ForegroundColor},
        ${BackgroundColor}) 
        
        process
        {
        }
}

Describe "Package-VSProject" {
    $Context = Create-Object @{NuGetExe = 'mynuget.exe'}
	[System.Collections.ArrayList]$capturedCalls = New-Object System.Collections.ArrayList
	
	function Call-Program([parameter(Position=0, ValueFromRemainingArguments=$true)] $arguments) {
		$capturedCalls.Add($arguments)
	}

    It "It should call Nuget with default parameters" {
		$capturedCalls.Clear()
        Package-VsProject 'abc.csproj'

        $capturedCalls.Count | Should Be 1
        $capturedCalls[0] | %{$_} | Should Be @($Context.NuGetExe,'pack', 'abc.csproj', '-Prop', 'Configuration=Release', '-Prop', 'Platform=AnyCPU', '-NonInteractive', '-Output', '.', '-IncludeReferencedProjects')
    }

    It "It should call Nuget with specified parameters" {
		$capturedCalls.Clear()
        Package-VsProject 'my project.csproj' -Configuration 'Debug' -IncludeReferencedProjects $false -Symbols $true -Version '3.2.1' -Output 'my folder' -Platform 'x86'

        $capturedCalls.Count | Should Be 1
        $capturedCalls[0] | %{$_} | Should Be @($Context.NuGetExe,'pack', 'my project.csproj', '-Prop', 'Configuration=Debug', '-Prop', 'Platform=x86', '-NonInteractive', '-Output', 'my folder', '-Symbols', '-Version', '3.2.1')
    }
	
	It "It should pipe project paths" {
		$capturedCalls.Clear()
		function List-Projects (){
			'a.csproj'
			'b.csproj'
		}
		
        List-Projects | Package-VsProject

        $capturedCalls.Count | Should Be 2
        $capturedCalls[0] | %{$_} | Should Be @($Context.NuGetExe,'pack', 'a.csproj', '-Prop', 'Configuration=Release', '-Prop', 'Platform=AnyCPU', '-NonInteractive', '-Output', '.', '-IncludeReferencedProjects')
		$capturedCalls[1] | %{$_} | Should Be @($Context.NuGetExe,'pack', 'b.csproj', '-Prop', 'Configuration=Release', '-Prop', 'Platform=AnyCPU', '-NonInteractive', '-Output', '.', '-IncludeReferencedProjects')
    }
}

Describe "Package-DeployableNuSpec" {
    $Context = Create-Object @{NuGetExe = 'mynuget.exe'}
	[System.Collections.ArrayList]$capturedCalls = New-Object System.Collections.ArrayList
	
	function Call-Program([parameter(Position=0)]$command, [parameter(Position=1, ValueFromRemainingArguments=$true)] $arguments) {
		$capturedCalls.Add(@($command,$arguments))
	}

    It "It should call Nuget with default parameters" {
		$capturedCalls.Clear()
        Package-DeployableNuSpec 'abc.nuspec'

        $capturedCalls.Count | Should Be 1
        $capturedCalls[0] | %{$_} | Should Be @($Context.NuGetExe,'pack', 'abc.nuspec', '-NonInteractive', '-Output', '.', '-NoPackageAnalysis')
    }

    It "It should call Nuget with specified parameters" {
		$capturedCalls.Clear()
        Package-DeployableNuSpec 'my project.nuspec' -NoPackageAnalysis $false -NoDefaultExcludes $true -Version '3.2.1' -Output 'my folder'

        $capturedCalls.Count | Should Be 1
        $capturedCalls[0] | %{$_} | Should Be @($Context.NuGetExe,'pack', 'my project.nuspec', '-NonInteractive', '-Output', 'my folder', '-NoDefaultExcludes', '-Version', '3.2.1')
    }
	
	It "It should pipe project paths" {
		$capturedCalls.Clear()
		function List-Projects (){
			'a.nuspec'
			'b.nuspec'
		}
		
        List-Projects | Package-DeployableNuSpec

        $capturedCalls.Count | Should Be 2        
        $capturedCalls[0] | %{$_} | Should Be @($Context.NuGetExe,'pack', 'a.nuspec', '-NonInteractive', '-Output', '.', '-NoPackageAnalysis')
		$capturedCalls[1] | %{$_} | Should Be @($Context.NuGetExe,'pack', 'b.nuspec', '-NonInteractive', '-Output', '.', '-NoPackageAnalysis')
    }
}

Describe "Finding packable artifacts" {
	$tmp = "$PSScriptRoot\temp"
	rmdir "$tmp" -Force -Recurse -ErrorAction "SilentlyContinue"
	mkdir "$tmp"
	mkdir "$tmp\inner"
	set-content "$tmp\a.csproj" ""
	set-content "$tmp\a.nuspec" ""
	set-content "$tmp\b.csproj" ""
	set-content "$tmp\c.nuspec" ""
	set-content "$tmp\d-suffix.csproj" ""
	set-content "$tmp\d-suffix.nuspec" ""
	set-content "$tmp\inner\e.csproj" ""
	set-content "$tmp\inner\e.nuspec" ""
	set-content "$tmp\prefix-f.csproj" ""
	set-content "$tmp\prefix-f.nuspec" ""
	set-content "$tmp\v.vbproj" ""
	set-content "$tmp\v.nuspec" ""
	
	It "Find-VSProjectsForPackaging should find packable projects" {
		$paths = Find-VSProjectsForPackaging $tmp
		$paths | Should Be @("$tmp\a.csproj", "$tmp\d-suffix.csproj", "$tmp\inner\e.csproj", "$tmp\prefix-f.csproj")
	}
	
	It "Find-VSProjectsForPackaging should find packable projects with custom filter" {
		$paths = Find-VSProjectsForPackaging $tmp -Filter "*.*proj"
		$paths | Should Be @("$tmp\a.csproj", "$tmp\d-suffix.csproj", "$tmp\inner\e.csproj","$tmp\prefix-f.csproj","$tmp\v.vbproj")
	}
	
	It "Find-VSProjectsForPackaging should find packable projects with custom filter and exclude" {
		$paths = Find-VSProjectsForPackaging $tmp -Filter "*.*proj" -Exclude "*-suffix.*","prefix-*"
		$paths | Should Be @("$tmp\a.csproj","$tmp\v.vbproj","$tmp\inner\e.csproj")
	}
	
	It "Find-NuSpecFiles should find nuspec files" {
		$paths = Find-NuSpecFiles $tmp
		$paths | Should Be @("$tmp\a.nuspec","$tmp\c.nuspec","$tmp\d-suffix.nuspec","$tmp\inner\e.nuspec","$tmp\prefix-f.nuspec","$tmp\v.nuspec")
	}
	
	It "Find-NuSpecFiles should find nuspec files with custom filter and exclude" {
		$paths = Find-NuSpecFiles $tmp -Filter "?.nuspec" -Exclude "a.nuspec","c.nuspec"
		$paths | Should Be @("$tmp\inner\e.nuspec","$tmp\v.nuspec")
	}
}
