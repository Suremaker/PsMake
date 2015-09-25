$psmake = "$PSScriptRoot\..\psmake\psmake.ps1"
$expectedVersion = '3.1.4.0'

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

function Capture-WriteHost($command)
{
    $output = @()
    $cmd = "& $command | Out-Null"
    Write-Host $cmd
    powershell.exe -noprofile -command $cmd | %{ $output += $_ }
    return $output
}

function Create-MakeDir(){ $dir = [guid]::NewGuid().ToString(); return mkdir "$PSScriptRoot\temp\$dir"; }

function Read-Ascii($file) { return [System.Text.Encoding]::ASCII.GetString([System.IO.File]::ReadAllBytes("$file")) }

Describe "List-AvailableModules" {
        
    It "Should list all available modules" {
        $modules = & $psmake -lam -NuGetSource "$PSScriptRoot\repo1;$PSScriptRoot\repo2"
        $modules.Count | Should Be 3
        $modules.Contains('psmake.mod.test') | Should Be $true
        $modules.Get_Item('psmake.mod.test') | Should Be '1.0.0.0'
        $modules.Contains('psmake.mod.test2') | Should Be $true
        $modules.Get_Item('psmake.mod.test2') | Should Be '1.0.0.0'
        $modules.Contains('psmake.mod.test-other') | Should Be $true
        $modules.Get_Item('psmake.mod.test-other') | Should Be '2.0.3.0'
    }

    It "Should print that it is listing available modules" {
        
        $output = Capture-WriteHost "$psmake -lam -NuGetSource $PSScriptRoot\repo1"
        $output -join '\r\n' | Should Be 'Listing available modules...'
    }
}

Describe "Add-Module" {
    It "Should add module with specified version" {
        $md = Create-MakeDir
        & $psmake -md $md -AddModule -ModuleName 'psmake.mod.test-other' -ModuleVersion '2.0.3.0' -NuGetsource "$PSScriptRoot\repo2"

        Test-Path "$md\Modules.ps1" |Should Be $true
        $modules = & "$md\Modules.ps1"
        $modules.Count | Should Be 1
        $modules.Contains('psmake.mod.test-other') | Should Be $true
        $modules.Get_Item('psmake.mod.test-other') | Should Be '2.0.3.0'
    }

    It "Should add 2 modules with specified version" {
        $md = Create-MakeDir
        & $psmake -md $md -AddModule -ModuleName 'psmake.mod.test-other' -ModuleVersion '2.0.3.0' -NuGetsource "$PSScriptRoot\repo2"
        & $psmake -md $md -AddModule -ModuleName 'psmake.mod.test' -ModuleVersion '1.0.0.0' -NuGetsource "$PSScriptRoot\repo1"

        Test-Path "$md\Modules.ps1" |Should Be $true
        $modules = & "$md\Modules.ps1"
        $modules.Count | Should Be 2
        $modules.Contains('psmake.mod.test-other') | Should Be $true
        $modules.Get_Item('psmake.mod.test-other') | Should Be '2.0.3.0'
        $modules.Contains('psmake.mod.test') | Should Be $true
        $modules.Get_Item('psmake.mod.test') | Should Be '1.0.0.0'
    }

    It "Should throw if module is already added" {
        $md = Create-MakeDir
        & $psmake -md $md -AddModule -ModuleName 'psmake.mod.test-other' -ModuleVersion '2.0.3.0' -NuGetsource "$PSScriptRoot\repo2"
        
        try
        {
            & $psmake -md $md -AddModule -ModuleName 'psmake.mod.test-other' -ModuleVersion '2.0.3.0' -NuGetsource "$PSScriptRoot\repo2"
            throw 'Failed'
        }
        catch [Exception]
        {
            $_.Exception.Message | Should Be 'Module psmake.mod.test-other is already added.'
        }
    }

    It "Should throw if requested module has wrong name" {
        $md = Create-MakeDir        
        
        try
        {
            & $psmake -md $md -AddModule -ModuleName 'psmake' -ModuleVersion '0.0.0.1' -NuGetsource "$PSScriptRoot\repo2"
            throw 'Failed'
        }
        catch [Exception]
        {
            $_.Exception.Message | Should Be 'Invalid module name psmake. A proper module name has to start with: psmake.mod.'
        }
    }

    It "Should throw if requested module has no entry point" {
        $md = Create-MakeDir        
        
        try
        {
            & $psmake -md $md -AddModule -ModuleName 'psmake.mod.test2' -ModuleVersion '1.0.0.0' -NuGetsource "$PSScriptRoot\repo1"
            throw 'Failed'
        }
        catch [Exception]
        {
            $_.Exception.Message | Should Be "Invalid module: unable to locate entry point: $md\packages\psmake.mod.test2.1.0.0.0\psmake.mod.test2.ps1"
        }
    }
}

Describe "List-Modules" {
        
    It "Should list all modules" {
        $md = Create-MakeDir
        & $psmake -md $md -AddModule -ModuleName 'psmake.mod.test-other' -ModuleVersion '2.0.3.0' -NuGetsource "$PSScriptRoot\repo2"
        & $psmake -md $md -AddModule -ModuleName 'psmake.mod.test' -ModuleVersion '1.0.0.0' -NuGetsource "$PSScriptRoot\repo1"

        $modules = & $psmake -lm -md $md

        $modules.Count | Should Be 2
        $modules.Contains('psmake.mod.test') | Should Be $true
        $modules.Get_Item('psmake.mod.test') | Should Be '1.0.0.0'
        $modules.Contains('psmake.mod.test-other') | Should Be $true
        $modules.Get_Item('psmake.mod.test-other') | Should Be '2.0.3.0'
    }

    It "Should print that it is listing modules" {
        $md = Create-MakeDir
        & $psmake -md $md -AddModule -ModuleName 'psmake.mod.test-other' -ModuleVersion '2.0.3.0' -NuGetsource "$PSScriptRoot\repo2"
        & $psmake -md $md -AddModule -ModuleName 'psmake.mod.test' -ModuleVersion '1.0.0.0' -NuGetsource "$PSScriptRoot\repo1"

        $output = Capture-WriteHost "$psmake -lm -md $md"
        $output -join '\r\n' | Should Be 'Reading modules...'
    }
}

Describe "Update-Modules" {
        
    It "Should update all modules" {
        $md = Create-MakeDir

        Set-Content "$md\Modules.ps1" "Write-Output @{'psmake.mod.test-other'='2.0.2.9';'psmake.mod.test'='1.0.0.1'}" | Out-Null        
        & $psmake -md $md -uam -NuGetsource "$PSScriptRoot\repo1;$PSScriptRoot\repo2"

        $modules = & $psmake -lm -md $md

        $modules.Count | Should Be 2
        $modules.Contains('psmake.mod.test') | Should Be $true
        $modules.Get_Item('psmake.mod.test') | Should Be '1.0.0.1'
        $modules.Contains('psmake.mod.test-other') | Should Be $true
        $modules.Get_Item('psmake.mod.test-other') | Should Be '2.0.3.0'
    }

    It "Should print that it is updating modules" {
        $md = Create-MakeDir
        Set-Content "$md\Modules.ps1" "Write-Output @{'psmake.mod.test-other'='2.0.2.9';'psmake.mod.test'='1.0.0.1'}" | Out-Null        

        $output = Capture-WriteHost "$psmake -md $md -uam -NuGetsource '$PSScriptRoot\repo1;$PSScriptRoot\repo2'"
        $output -join "`r`n" | Should Be @"
Listing available modules...
Reading modules...
Updating modules...
Updating psmake.mod.test-other ver. 2.0.2.9 to ver. 2.0.3.0
Fetching psmake.mod.test-other ver. 2.0.3.0...
.nuget\NuGet.exe install psmake.mod.test-other -Version 2.0.3.0 -OutputDirectory $md\packages -Verbosity detailed -Source $PSScriptRoot\repo1;$PSScriptRoot\repo2 -ConfigFile .nuget\NuGet.Config
Installing 'psmake.mod.test-other 2.0.3.0'.
Successfully installed 'psmake.mod.test-other 2.0.3.0'.
Module psmake.mod.test ver. 1.0.0.1 is up to date.
"@
    }
}

Describe "Get-Version" {
        
    It "Should return version number" {
        $ver = & $psmake -GetVersion
        $ver | Should Match '^[0-9]+(\.[0-9]+){0,3}$'
    }
}

Describe "Scaffold" {
        
    It "Should generate Defaults.ps1 with NuGetSource and NuGetConfig" {
        $md = Create-MakeDir
        & $psmake -Scaffold empty -md $md -NuGetSource source -NuGetConfig config
        Test-Path "$md\Defaults.ps1" | Should Be $true
        $content = Read-Ascii "$md\Defaults.ps1"
        $content | Should Be @"
Write-Output @{
`t'NuGetSource' = 'source';
`t'NuGetConfig' = 'config'
}

"@
    }

    It "Should generate Defaults.ps1 with NuGetConfig" {
        $md = Create-MakeDir
        & $psmake -Scaffold empty -md $md -NuGetConfig config
        Test-Path "$md\Defaults.ps1" | Should Be $true
        $content = Read-Ascii "$md\Defaults.ps1"
        $content | Should Be @"
Write-Output @{
`t'NuGetConfig' = 'config'
}

"@
    }

    It "Should generate Defaults.ps1 with default config" {
        $md = Create-MakeDir
        & $psmake -Scaffold empty -md $md
        Test-Path "$md\Defaults.ps1" | Should Be $true
        $content = Read-Ascii "$md\Defaults.ps1"
        $content | Should Be @"
Write-Output @{
`t'NuGetConfig' = '.nuget\NuGet.Config'
}

"@
    }

    It "Should generate Makefile.ps1 with default steps" {
        $md = Create-MakeDir
        & $psmake -Scaffold empty -md $md
        Test-Path "$md\Makefile.ps1" | Should Be $true
        $content = Read-Ascii "$md\Makefile.ps1"
        $content | Should Be @"
Define-Step -Name 'Step one' -Target 'build' -Body {
`techo 'Greetings from step one'
}

Define-Step -Name 'Step two' -Target 'build,deploy' -Body {
`techo 'Greetings from step two'
}

"@
    }

    It "Should generate make.ps1 with psmake version, make directory, config and source" {
        $md = Create-MakeDir
        & $psmake -Scaffold empty -md $md -nugetsource source -nugetconfig config -nugetexe folder\nuget.exe
        Test-Path "$md\Make.ps1" | Should Be $true
        $content = Read-Ascii "$md\Make.ps1"
        $content -like "*`$private:PsMakeVer = '$expectedVersion'*" | Should Be $true
        $content -like "*`$private:PsMakeNugetSource = 'source'*" | Should Be $true
        $content -like "*folder\nuget.exe install psmake -Version `$PsMakeVer -OutputDirectory $md -ConfigFile config @srcArgs*" | Should Be $true
        $content -like "*& `"$md\psmake.`$PsMakeVer\psmake.ps1`" -md $md @args*" | Should Be $true
    }

    It "Should generate make.ps1 with psmake version, config and make directory" {
        $md = Create-MakeDir
        & $psmake -Scaffold empty -md $md -nugetconfig config -nugetexe folder\nuget.exe
        Test-Path "$md\Make.ps1" | Should Be $true
        $content = Read-Ascii "$md\Make.ps1"
        $content -like "*`$private:PsMakeVer = '$expectedVersion'*" | Should Be $true
        $content -like "*`$private:PsMakeNugetSource = `$null*" | Should Be $true
        $content -like "*folder\nuget.exe install psmake -Version `$PsMakeVer -OutputDirectory $md -ConfigFile config @srcArgs*" | Should Be $true
        $content -like "*& `"$md\psmake.`$PsMakeVer\psmake.ps1`" -md $md @args*" | Should Be $true
    }

    It "Should generate make.ps1 with psmake version, make directory and default config and nuget.exe" {
        $md = Create-MakeDir
        & $psmake -Scaffold empty -md $md
        Test-Path "$md\Make.ps1" | Should Be $true
        $content = Read-Ascii "$md\Make.ps1"
        $content -like "*`$private:PsMakeVer = '$expectedVersion'*" | Should Be $true
        $content -like "*`$private:PsMakeNugetSource = `$null*" | Should Be $true
        $content -like "*.nuget\nuget.exe install psmake -Version `$PsMakeVer -OutputDirectory $md -ConfigFile .nuget\NuGet.Config @srcArgs*" | Should Be $true
        $content -like "*& `"$md\psmake.`$PsMakeVer\psmake.ps1`" -md $md @args*" | Should Be $true
    }
}

Describe "Make" {
        
    It "Should run all steps" {
        $md = Create-MakeDir
        Set-Content "$md\Makefile.ps1" @"
Define-Step -Name 'Step one' -Target 'build' -Body { Write-Output 'A' }
Define-Step -Name 'Step two' -Target 'build,deploy' -Body { Write-Output 'B' }
Define-Step -Name 'Step two' -Target 'deploy' -Body { Write-Output 'C' }
"@

        $output = & $psmake -md $md -t build
        $output -join '|' | Should Be 'A|B'

        $output = & $psmake -md $md -t deploy
        $output -join '|' | Should Be 'B|C'
    }

    It "Should load Environment.ps1 before steps, and preserve original state between steps" {
        $md = Create-MakeDir
        Set-Content "$md\Environment.ps1" "`$Value='abc'"

        Set-Content "$md\Makefile.ps1" @"
Define-Step -Name 'Step one' -Target 'build' -Body { Write-Output `$Value; `$Value='bcd'; Write-Output `$Value; }
Define-Step -Name 'Step two' -Target 'build' -Body { Write-Output `$Value; }
"@

        $output = & $psmake -md $md -t build
        $output -join '|' | Should Be 'abc|bcd|abc'
    }

    It "Should allow to use modules within steps, but enforce to use Require-Module before accessing it's methods" {
        $md = Create-MakeDir
        & $psmake -md $md -AddModule -ModuleName 'psmake.mod.test' -ModuleVersion '1.0.0.0' -NuGetsource "$PSScriptRoot\repo1"

        Set-Content "$md\Makefile.ps1" @"
Define-Step -Name 'Step one' -Target 'build,deploy' -Body { . (require 'psmake.mod.test'); Test; }
Define-Step -Name 'Step two' -Target 'deploy' -Body { Test; }
"@

        $output = & $psmake -md $md -t build
        $output -join '|' | Should Be 'test'

        try
        {
            & $psmake -md $md -t deploy
            throw 'Fail'
        }
        catch [Exception]
        {
            $_.Exception.Message | Should Match "The term 'Test' is not recognized as the name of a cmdlet"
        }
    }
    
    It "Require-Module should return a full path to module" {
        $md = Create-MakeDir
        & $psmake -md $md -AddModule -ModuleName 'psmake.mod.test' -ModuleVersion '1.0.0.0' -NuGetsource "$PSScriptRoot\repo1"

        Set-Content "$md\Makefile.ps1" @"
Define-Step -Name 'Step one' -Target 'build' -Body { Write-Output (require 'psmake.mod.test'); }
"@

        $output = & $psmake -md $md -t build
        $expected = [System.IO.Path]::GetFullPath("$md\packages\psmake.mod.test.1.0.0.0\psmake.mod.test.ps1")
        $output -join '|' | Should Be $expected
    }
}