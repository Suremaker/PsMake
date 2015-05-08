$here = (Split-Path -Parent $MyInvocation.MyCommand.Path).Replace(".Tests", "")
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\ext\$sut"

Describe "Call-Program" {
    function Test ($arg, $arg2) { Set-Content 'tmp.txt' "$arg $arg2" }
        
    It "Calls specified command with parameters" {
        Call-Program Test 'a' 2
        $c = Get-Content 'tmp.txt' 
        remove-item 'tmp.txt'
        $c | Should Match "a 2"
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

    It "Prints command stderr on Write-Host" {

        $captured=@{}
        try
        {
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
                        $captured.Add("$_".Trim(),'')
                    }
            }
            call 'cmd.exe' '/c' 'echo message 1>&2'
            throw 'Call-Program should throw.'
        }
        catch [Exception]
        {
            Remove-Item function:\Write-Host
            $captured.ContainsKey('message') | Should Be $true
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

Describe "Make-ScriptBlock" {
    $Context = Create-Object @{Prop1='ABC'}
    $Modules = @{'psmake.core'=Create-Object @{File="$here\ext\$sut"}}

    It "Should create script-block having access to all core features" {
        $block = Make-ScriptBlock "Write-Output (Create-Object @{Ctx=`$Context; Md=`$Modules})" $false
        $result = & $block
        $result.Ctx | Should be $Context
        $result.Md | Should be $Modules
    }

    It "Should create script-block having access to all core features if called externally" {
        $block = Make-ScriptBlock "return (Create-Object @{Ctx=`$Context; Md=`$Modules})"

        $job = start-job -scriptblock $block 
        $result = receive-job $job -Wait

        $result.Ctx | Should not be $null
        $result.Ctx.Prop1 | Should be $Context.Prop1
        $result.Md | Should not be $null
        $result.Md.Contains('psmake.core') | Should be $true
        $result.Md.Get_Item('psmake.core') | Should not be $null
        $result.Md.Get_Item('psmake.core').File | Should be $Modules.Get_Item('psmake.core').File
    }
}