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

Describe "Update-VersionInAssemblyInfo" {
    
    function SetupAssemblyInfoFiles
    {
        rmdir "$PSScriptRoot\proj" -Force -Recurse -ErrorAction "SilentlyContinue"
        rmdir "$PSScriptRoot\proj2" -Force -Recurse -ErrorAction "SilentlyContinue"
        mkdir "$PSScriptRoot\proj"
        mkdir "$PSScriptRoot\proj2"
        mkdir "$PSScriptRoot\proj\inner"

        set-content "$PSScriptRoot\proj2\AssemblyInfo.cs" "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""1.0.0.0"")]`n[assembly: AssemblyFileVersion(""1.0.0.0"")]"
        set-content "$PSScriptRoot\proj\AssemblyInfo.cs" "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""1.0"")]`n[assembly: AssemblyFileVersion(""1.0.0"")]"
        set-content "$PSScriptRoot\proj\inner\AssemblyInfo.cs" "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""1.0.0.0"")]`n[assembly: AssemblyFileVersion(""1.0.0.0"")]"
        set-content "$PSScriptRoot\proj\inner\OtherFile.cs" "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""1.0.0.0"")]`n[assembly: AssemblyFileVersion(""1.0.0.0"")]"
        set-content "$PSScriptRoot\proj\OtherFile.cs" "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""1.0.0.0"")]`n[assembly: AssemblyFileVersion(""1.0.0.0"")]"
    }
	
    It "It should update AsseblyInfo.cs versions" {
        
        SetupAssemblyInfoFiles

        Update-VersionInAssemblyInfo '4.3.2.1' "$PSScriptRoot\proj"
        
        (get-content "$PSScriptRoot\proj2\AssemblyInfo.cs") -join "`n" | Should Be "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""1.0.0.0"")]`n[assembly: AssemblyFileVersion(""1.0.0.0"")]"
        (get-content "$PSScriptRoot\proj\AssemblyInfo.cs") -join "`n" | Should Be "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""4.3.2.1"")]`n[assembly: AssemblyFileVersion(""4.3.2.1"")]"
        (get-content "$PSScriptRoot\proj\inner\AssemblyInfo.cs") -join "`n" | Should Be "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""4.3.2.1"")]`n[assembly: AssemblyFileVersion(""4.3.2.1"")]"
        (get-content "$PSScriptRoot\proj\inner\OtherFile.cs") -join "`n" | Should Be "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""1.0.0.0"")]`n[assembly: AssemblyFileVersion(""1.0.0.0"")]"
        (get-content "$PSScriptRoot\proj\OtherFile.cs") -join "`n" | Should Be "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""1.0.0.0"")]`n[assembly: AssemblyFileVersion(""1.0.0.0"")]"
    }
	
	It "It should update versions in specified assembly info files" {

        SetupAssemblyInfoFiles

        Update-VersionInAssemblyInfo '4.3.2.1' "$PSScriptRoot\proj" ("OtherFile.cs")
        
        (get-content "$PSScriptRoot\proj2\AssemblyInfo.cs") -join "`n" | Should Be "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""1.0.0.0"")]`n[assembly: AssemblyFileVersion(""1.0.0.0"")]"
        (get-content "$PSScriptRoot\proj\AssemblyInfo.cs") -join "`n" | Should Be "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""1.0"")]`n[assembly: AssemblyFileVersion(""1.0.0"")]"
        (get-content "$PSScriptRoot\proj\inner\AssemblyInfo.cs") -join "`n" | Should Be "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""1.0.0.0"")]`n[assembly: AssemblyFileVersion(""1.0.0.0"")]"
        (get-content "$PSScriptRoot\proj\inner\OtherFile.cs") -join "`n" | Should Be "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""4.3.2.1"")]`n[assembly: AssemblyFileVersion(""4.3.2.1"")]"
        (get-content "$PSScriptRoot\proj\OtherFile.cs") -join "`n" | Should Be "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""4.3.2.1"")]`n[assembly: AssemblyFileVersion(""4.3.2.1"")]"
    }
	
	It "It should update AsseblyInfo.cs versions everywhere except Exclusions" {
        
        SetupAssemblyInfoFiles

        Update-VersionInAssemblyInfo '4.3.2.1' "$PSScriptRoot" -Exclude "*inner*","*proj2*"
        
        (get-content "$PSScriptRoot\proj2\AssemblyInfo.cs") -join "`n" | Should Be "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""1.0.0.0"")]`n[assembly: AssemblyFileVersion(""1.0.0.0"")]"
        (get-content "$PSScriptRoot\proj\AssemblyInfo.cs") -join "`n" | Should Be "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""4.3.2.1"")]`n[assembly: AssemblyFileVersion(""4.3.2.1"")]"
        (get-content "$PSScriptRoot\proj\inner\AssemblyInfo.cs") -join "`n" | Should Be "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""1.0.0.0"")]`n[assembly: AssemblyFileVersion(""1.0.0.0"")]"
        (get-content "$PSScriptRoot\proj\inner\OtherFile.cs") -join "`n" | Should Be "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""1.0.0.0"")]`n[assembly: AssemblyFileVersion(""1.0.0.0"")]"
        (get-content "$PSScriptRoot\proj\OtherFile.cs") -join "`n" | Should Be "[assembly: SomethingOther(""1.0"")]`n[assembly: AssemblyVersion(""1.0.0.0"")]`n[assembly: AssemblyFileVersion(""1.0.0.0"")]"
    }
}

Describe "Update-VersionInFile" {
    
    It "It should update file versions" {
        set-content "$PSScriptRoot\file.txt" "Version(abc), Version(1), Version(1.2), Version(1.2.3), Version(1.2.3.4), Version(1.2.3.4.555), Other(3.2), Else(1.2)"

        Update-VersionInFile "$PSScriptRoot\file.txt" '3.2.1' 'Version(%)','Other(%)'
        
        get-content "$PSScriptRoot\file.txt" | Should Be "Version(abc), Version(3.2.1), Version(3.2.1), Version(3.2.1), Version(3.2.1), Version(1.2.3.4.555), Other(3.2.1), Else(1.2)"
    }
}