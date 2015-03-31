$here = (Split-Path -Parent $MyInvocation.MyCommand.Path).Replace(".Tests", "")
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

Describe "Call-Program" {
    function Test ($arg, $arg2) { Set-Content 'tmp.txt' "$arg $arg2" }
        
    It "Calls specified command with parameters" {
        Call-Program Test 'a' 2
        Get-Content 'tmp.txt' | Should Match "a 2"
    }

    It "Reports error if command exit with error" {
        try
        {
            Call-Program cmd.exe /c "exit 1"
            throw 'Call-Program should throw.'
        }
        catch [Exception]
        {
            $_.Exception.Message | Should Be 'A program execution was not successful (Exit code: 1).'
        }
    }
}

Describe "Create-Object" {
    It "Should create object with all properties" {
        $obj = Create-Object @{Prop1='abc';Prop2=22;Prop3=$null}

        $obj | Should not be $null
        $obj.Prop1 | Should be 'abc'
        $obj.Prop2 | Should be 22
        $obj.Prop3 | Should be $null
    }
}

Describe "Require-Module" {
    $Modules = @{'Abc'=Create-Object @{File='def'} }

    It "Should return module path" {
        Require-Module 'Abc' | Should Be 'def'
    }

    It "Should throw if module does not exist" {
        try 
        {
            Require-Module 'Other'
            throw 'Failed.'
        }
        catch [Exception]
        {
            $_.Exception.Message | Should Be 'Module Other is not added. Please add it first with psmake.ps1 -AddModule.'
        }
    }
}