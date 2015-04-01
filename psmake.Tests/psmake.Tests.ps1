$psmake = "$PSScriptRoot\..\psmake\psmake.ps1"

function Capture-WriteHost($command)
{
    $output = @()
    $cmd = "& $command | Out-Null"
    Write-Host $cmd
    powershell.exe -noprofile -command $cmd | %{ $output += $_ }
    return $output
}

function Create-MakeDir(){ $dir = [guid]::NewGuid().ToString(); return mkdir "$PSScriptRoot\temp\$dir"; }

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