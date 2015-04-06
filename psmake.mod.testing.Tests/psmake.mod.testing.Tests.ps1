$here = (Split-Path -Parent $MyInvocation.MyCommand.Path).Replace(".Tests", "")
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\..\psmake\ext\psmake.core.ps1"
. "$here\$sut"

# Prepare test projects
call "$($env:windir)\Microsoft.NET\Framework64\v4.0.30319\msbuild.exe" "$PSScriptRoot\TestSolution\Testsolution.sln" /t:"Clean,Build" /p:Configuration=Release /m /verbosity:m /nologo /p:TreatWarningsAsErrors=true


Describe "Define-NUnitTests" {
    
    It "It should use group name as report name if second is not sepcified" {
        $def = Define-NUnitTests -GroupName 'my group' -TestAssembly "some.dll"
        $def | Should Not Be $null
        $def.GroupName | Should Be 'my group'
        $def.ReportName | Should Be 'my_group'
    }

    It "It should define tests with group name and report name" {
        $def = Define-NUnitTests -GroupName 'my group' -ReportName 'test-reports' -TestAssembly "some.dll"
        $def | Should Not Be $null
        $def.GroupName | Should Be 'my group'
        $def.ReportName | Should Be 'test-reports'
    }

    It "It should define tests with default runner version" {
        $def = Define-NUnitTests -GroupName 'my group' -TestAssembly "some.dll"
        $def | Should Not Be $null
        $def.PackageVersion | Should Be '2.6.3'
    }

    It "It should define tests with sepcified runner version" {
        $def = Define-NUnitTests -GroupName 'my group' -NUnitVersion '2.6.4' -TestAssembly "some.dll"
        $def | Should Not Be $null
        $def.PackageVersion | Should Be '2.6.4'
    }
        
    It "It should allow to specify one assembly" {
        $def = Define-NUnitTests -GroupName 'group' -TestAssembly "$PSScriptRoot\TestSolution\Passing.NUnit.Tests1\bin\Release\Passing.NUnit.Tests1.dll"
        $def | Should Not Be $null
        $def.Assemblies.GetType() | Should Be 'string[]'
        $def.Assemblies.Length | Should Be 1
        $def.Assemblies[0] | Should Be "$PSScriptRoot\TestSolution\Passing.NUnit.Tests1\bin\Release\Passing.NUnit.Tests1.dll"
    }

    It "It should allow to specify multiple assemblies" {
        $def = Define-NUnitTests -GroupName 'group' -TestAssembly "$PSScriptRoot\TestSolution\Passing.NUnit.Tests1\bin\Release\Passing.NUnit.Tests1.dll", "$PSScriptRoot\TestSolution\Passing.NUnit.Tests2\bin\Release\Passing.NUnit.Tests2.dll"
        $def | Should Not Be $null
        $def.Assemblies.GetType() | Should Be 'string[]'
        $def.Assemblies.Length | Should Be 2
        $def.Assemblies[0] | Should Be "$PSScriptRoot\TestSolution\Passing.NUnit.Tests1\bin\Release\Passing.NUnit.Tests1.dll"
        $def.Assemblies[1] | Should Be "$PSScriptRoot\TestSolution\Passing.NUnit.Tests2\bin\Release\Passing.NUnit.Tests2.dll"
    }

    It "It should resolve assembly names with wildcards" {
        $def = Define-NUnitTests -GroupName 'group' -TestAssembly "$PSScriptRoot\TestSolution\*\bin\Release\*.NUnit.Tests*.dll"
        $def | Should Not Be $null
        $def.Assemblies.GetType() | Should Be 'string[]'
        $def.Assemblies.Length | Should Be 3
        $def.Assemblies.Contains("$PSScriptRoot\TestSolution\Passing.NUnit.Tests1\bin\Release\Passing.NUnit.Tests1.dll") | Should Be $true
        $def.Assemblies.Contains("$PSScriptRoot\TestSolution\Passing.NUnit.Tests2\bin\Release\Passing.NUnit.Tests2.dll") | Should Be $true
        $def.Assemblies.Contains("$PSScriptRoot\TestSolution\Failing.NUnit.Tests\bin\Release\Failing.NUnit.Tests.dll") | Should Be $true
    }
}

Describe "Define-MbUnitTests" {
    
    It "It should use group name as report name if second is not sepcified" {
        $def = Define-MbUnitTests -GroupName 'my group' -TestAssembly "some.dll"
        $def | Should Not Be $null
        $def.GroupName | Should Be 'my group'
        $def.ReportName | Should Be 'my_group'
    }

    It "It should define tests with group name and report name" {
        $def = Define-MbUnitTests -GroupName 'my group' -ReportName 'test-reports' -TestAssembly "some.dll"
        $def | Should Not Be $null
        $def.GroupName | Should Be 'my group'
        $def.ReportName | Should Be 'test-reports'
    }

    It "It should define tests with default runner version" {
        $def = Define-MbUnitTests -GroupName 'my group' -TestAssembly "some.dll"
        $def | Should Not Be $null
        $def.PackageVersion | Should Be '3.4.14.0'
    }

    It "It should define tests with sepcified runner version" {
        $def = Define-MbUnitTests -GroupName 'my group' -MbUnitVersion '3.4.15.0' -TestAssembly "some.dll"
        $def | Should Not Be $null
        $def.PackageVersion | Should Be '3.4.15.0'
    }
        
    It "It should allow to specify one assembly" {
        $def = Define-MbUnitTests -GroupName 'group' -TestAssembly "$PSScriptRoot\TestSolution\Passing.MbUnit.Tests1\bin\Release\Passing.MbUnit.Tests1.dll"
        $def | Should Not Be $null
        $def.Assemblies.GetType() | Should Be 'string[]'
        $def.Assemblies.Length | Should Be 1
        $def.Assemblies[0] | Should Be "$PSScriptRoot\TestSolution\Passing.MbUnit.Tests1\bin\Release\Passing.MbUnit.Tests1.dll"
    }

    It "It should allow to specify multiple assemblies" {
        $def = Define-MbUnitTests -GroupName 'group' -TestAssembly "$PSScriptRoot\TestSolution\Passing.MbUnit.Tests1\bin\Release\Passing.MbUnit.Tests1.dll", "$PSScriptRoot\TestSolution\Passing.MbUnit.Tests2\bin\Release\Passing.MbUnit.Tests2.dll"
        $def | Should Not Be $null
        $def.Assemblies.GetType() | Should Be 'string[]'
        $def.Assemblies.Length | Should Be 2
        $def.Assemblies[0] | Should Be "$PSScriptRoot\TestSolution\Passing.MbUnit.Tests1\bin\Release\Passing.MbUnit.Tests1.dll"
        $def.Assemblies[1] | Should Be "$PSScriptRoot\TestSolution\Passing.MbUnit.Tests2\bin\Release\Passing.MbUnit.Tests2.dll"
    }

    It "It should resolve assembly names with wildcards" {
        $def = Define-MbUnitTests -GroupName 'group' -TestAssembly "$PSScriptRoot\TestSolution\*\bin\Release\*.MbUnit.Tests*.dll"
        $def | Should Not Be $null
        $def.Assemblies.GetType() | Should Be 'string[]'
        $def.Assemblies.Length | Should Be 3
        $def.Assemblies.Contains("$PSScriptRoot\TestSolution\Passing.MbUnit.Tests1\bin\Release\Passing.MbUnit.Tests1.dll") | Should Be $true
        $def.Assemblies.Contains("$PSScriptRoot\TestSolution\Passing.MbUnit.Tests2\bin\Release\Passing.MbUnit.Tests2.dll") | Should Be $true
        $def.Assemblies.Contains("$PSScriptRoot\TestSolution\Failing.MbUnit.Tests\bin\Release\Failing.MbUnit.Tests.dll") | Should Be $true
    }
}

Describe "Define-MsTests" {
    
    It "It should use group name as report name if second is not sepcified" {
        $def = Define-MsTests -GroupName 'my group' -TestAssembly "some.dll"
        $def | Should Not Be $null
        $def.GroupName | Should Be 'my group'
        $def.ReportName | Should Be 'my_group'
    }

    It "It should define tests with group name and report name" {
        $def = Define-MsTests -GroupName 'my group' -ReportName 'test-reports' -TestAssembly "some.dll"
        $def | Should Not Be $null
        $def.GroupName | Should Be 'my group'
        $def.ReportName | Should Be 'test-reports'
    }

    It "It should define tests with default runner version" {
        $def = Define-MsTests -GroupName 'my group' -TestAssembly "some.dll"
        $def | Should Not Be $null
        $def.Runner | Should Match '12\.0'
    }

    It "It should define tests with sepcified runner version" {
        $def = Define-MsTests -GroupName 'my group' -VisualStudioVersion '11.0' -TestAssembly "some.dll"
        $def | Should Not Be $null
        $def.Runner | Should Match '11\.0'
    }
        
    It "It should allow to specify one assembly" {
        $def = Define-MsTests -GroupName 'group' -TestAssembly "$PSScriptRoot\TestSolution\Passing.MsTest.Tests1\bin\Release\Passing.MsTest.Tests1.dll"
        $def | Should Not Be $null
        $def.Assemblies.GetType() | Should Be 'string[]'
        $def.Assemblies.Length | Should Be 1
        $def.Assemblies[0] | Should Be "$PSScriptRoot\TestSolution\Passing.MsTest.Tests1\bin\Release\Passing.MsTest.Tests1.dll"
    }

    It "It should allow to specify multiple assemblies" {
        $def = Define-MsTests -GroupName 'group' -TestAssembly "$PSScriptRoot\TestSolution\Passing.MsTest.Tests1\bin\Release\Passing.MsTest.Tests1.dll", "$PSScriptRoot\TestSolution\Passing.MsTest.Tests2\bin\Release\Passing.MsTest.Tests2.dll"
        $def | Should Not Be $null
        $def.Assemblies.GetType() | Should Be 'string[]'
        $def.Assemblies.Length | Should Be 2
        $def.Assemblies[0] | Should Be "$PSScriptRoot\TestSolution\Passing.MsTest.Tests1\bin\Release\Passing.MsTest.Tests1.dll"
        $def.Assemblies[1] | Should Be "$PSScriptRoot\TestSolution\Passing.MsTest.Tests2\bin\Release\Passing.MsTest.Tests2.dll"
    }

    It "It should resolve assembly names with wildcards" {
        $def = Define-MsTests -GroupName 'group' -TestAssembly "$PSScriptRoot\TestSolution\*\bin\Release\*.MsTest.Tests*.dll"
        $def | Should Not Be $null
        $def.Assemblies.GetType() | Should Be 'string[]'
        $def.Assemblies.Length | Should Be 3
        $def.Assemblies.Contains("$PSScriptRoot\TestSolution\Passing.MsTest.Tests1\bin\Release\Passing.MsTest.Tests1.dll") | Should Be $true
        $def.Assemblies.Contains("$PSScriptRoot\TestSolution\Passing.MsTest.Tests2\bin\Release\Passing.MsTest.Tests2.dll") | Should Be $true
        $def.Assemblies.Contains("$PSScriptRoot\TestSolution\Failing.MsTest.Tests\bin\Release\Failing.MsTest.Tests.dll") | Should Be $true
    }
}