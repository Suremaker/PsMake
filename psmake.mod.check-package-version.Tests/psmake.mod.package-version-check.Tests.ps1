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

<# Disable Write-Error in tested code #>
$script:isWriteErrorFunctionInvoked = $false
function Write-Error
{
    param(
        [Parameter(Position=0)]
        $message
        ) 
        
        $script:isWriteErrorFunctionInvoked = $true
}

Describe "Checking that the same NuGet package version is used" {
    $tmp = "$PSScriptRoot\temp"
    rmdir "$tmp" -Force -Recurse -ErrorAction "SilentlyContinue"
    mkdir "$tmp"
    mkdir "$tmp\inner"
    mkdir "$tmp\inner\inner"
    mkdir "$tmp\inner\inner\inner"
    
    set-content "$tmp\packages.config" @"
<?xml version="1.0" encoding="utf-8"?>
<packages>
  <package id="Antlr" version="3.1.3.42154" targetFramework="net451" />
</packages>
"@

    set-content "$tmp\inner\packages.config" @"
<?xml version="1.0" encoding="utf-8"?>
<packages>
  <package id="Common.Logging" version="3.3.1" targetFramework="net40" />
</packages>
"@

    set-content "$tmp\inner\inner\packages.config" @"
<?xml version="1.0" encoding="utf-8"?>
<packages>
  <package id="Common.Logging" version="3.3.1" targetFramework="net451" />
</packages>
"@

    set-content "$tmp\inner\inner\inner\packages.config" @"
<?xml version="1.0" encoding="utf-8"?>
<packages>
  <package id="Common.Logging" version="3.3.1" targetFramework="net451" />
  <package id="Antlr" version="3.1.1" targetFramework="net451" />
</packages>
"@
    
    It "Ensure-SamePackageVersionIsUsed should not Write-Error when the same version and targetFramework are used" {
        $script:isWriteErrorFunctionInvoked = $false
        Ensure-SamePackageVersionIsUsed "$tmp\inner\inner"
        $script:isWriteErrorFunctionInvoked | Should Be $false
    }

    It "Ensure-SamePackageVersionIsUsed should Write-Error when packages have the same version but different targetFramework versions" {
        $script:isWriteErrorFunctionInvoked = $false
        Ensure-SamePackageVersionIsUsed "$tmp\inner"
        $script:isWriteErrorFunctionInvoked | Should Be $true
    }

    It "Ensure-SamePackageVersionIsUsed should not Write-Error when packages have the same version and different targetFramework versions but -IgnoreTargetFramework is enabled" {
        $script:isWriteErrorFunctionInvoked = $false
        Ensure-SamePackageVersionIsUsed -Path:"$tmp\inner" -IgnoreTargetFramework
        $script:isWriteErrorFunctionInvoked | Should Be $false
    }

    It "Ensure-SamePackageVersionIsUsed should not Write-Error when packages have the same version and different targetFramework versions but package name is added to Exceptions list" {
        $script:isWriteErrorFunctionInvoked = $false
        Ensure-SamePackageVersionIsUsed "$tmp\inner" -Exceptions('Common.Logging')
        $script:isWriteErrorFunctionInvoked | Should Be $false
    }
    
    It "Ensure-SamePackageVersionIsUsed should Write-Error when packages have the same targetFramework but different versions" {
        $script:isWriteErrorFunctionInvoked = $false
        $isSamePackageVersionUsed = Ensure-SamePackageVersionIsUsed $tmp -Exceptions('Common.Logging')
        $script:isWriteErrorFunctionInvoked | Should Be $true
    }

    It "Ensure-SamePackageVersionIsUsed should not Write-Error when packages have the same targetFramework and different versions but are added to Exceptions list" {
        $script:isWriteErrorFunctionInvoked = $false
        Ensure-SamePackageVersionIsUsed "$tmp\inner" -Exceptions('Common.Logging', 'Antlr')
        $script:isWriteErrorFunctionInvoked | Should Be $false
    }
}
