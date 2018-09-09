<#
.SYNOPSIS
A PowerShell based tool which controls a software project build process.

.DESCRIPTION
A PowerShell based tool which controls a software project build process.

.EXAMPLE
C:\Project> .\psmake.ps1 -Target build

Makes all steps associated with 'build' target.

.EXAMPLE
C:\Project> .\psmake.ps1 -Target build -NuGetSource "C:\LocalRepo;https://www.nuget.org/api/v2/" -NuGetExe C:\NuGet\NuGet.exe -NuGetConfig C:\NuGet\NuGet.Config -AnsiConsole -AdditionalParams packageVersion:5.2.2.7,requiredCoverage:85

Makes all steps associated with 'build' target.
Uses NuGet exe and config file from C:\NuGet directory for fetching packages from C:\LocalRepo and/or https://www.nuget.org/api/v2/.
During steps' execution, $Context.packageVersion and $Context.requiredCoverage variables are available, having '5.2.2.7' and '85' values.
Uses Ansi escape sequences for printing colors.

.EXAMPLE
C:\Project> .\psmake.ps1 -GetVersion

Returns psmake version.

.EXAMPLE
C:\Project> .\psmake.ps1 -RunSteps @("Step 1", "Step 2")

Only run "Step 1" and "Step 2", all other steps will be skipped

#>
[CmdletBinding(DefaultParameterSetName = "Make")]
param (
    [Parameter(Mandatory = $true, ParameterSetName = "Make")]
    [Alias('t')]
    [ValidateNotNullOrEmpty()]
    # Target to make. All steps annotated with this target would be made.
    [string] $Target,

    [Parameter()]
    [Alias('rs')]
    # Run only the steps specified
    [array]$RunSteps,

    [Parameter(Mandatory = $true, ParameterSetName = "Version")]
    # Prints psmake version.
    [switch] $GetVersion,

    [Parameter(ParameterSetName = "Make")]
    [Alias('ap')]
    # Additional make parameters that would be available for make steps via $Context variable.
    # Expected format:
    #	-AdditionalParams key1:value1,key2,key3:"abc,def"
    # It will result in $Context.key1 = value1, $Context.key2 = $true, $Context.key3 = "abc,def"
    [string[]] $AdditionalParams,

    [Parameter()]
    [AllowNull()]
    # NuGet source to use for fetching modules and packages. It can have semicolon separated urls/paths. If not specified, NuGet.exe would be called without source parameter.
    [string] $NuGetSource,

    [Parameter()]
    [AllowNull()]
    # NuGet.exe path like: .nuget\NuGet.exe. If not specified, PsMake will attempt to locate it in .nuget, then current directory, then on environment PATH, and if not found, it will download it.
    [string] $NuGetExe,

    [Parameter()]
    [AllowNull()]
    # NuGet.Config path like: .nuget\NuGet.Config. If not specified, PsMake will attempt to locate it in .nuget or current directory, or otherwise NuGet.exe will be executed without config file.
    [string] $NuGetConfig,

    [Parameter()]
    [Alias('ansi', 'ac')]
    # Makes Write-Host to write ANSI escaped colors - use only if script is running on terminal supporting ANSI escape sequences.
    [switch] $AnsiConsole
)

function private:Get-Version()
{
    return "4.0.0"
}

function private:Load-MakeFile()
{
    . $PSScriptRoot\ext\psmake.makefile.ps1;

    $path = ".\Makefile.ps1"
    Write-Header "Loading $path..."
    if (!(Test-Path $path))
    {
        Write-Error "$path does not exist, aborting..."
    }
    return [array] (& $path);
}

function private:Build-Context($makefile)
{
    $defaults = $makefile | Where-Object {$_.Type -eq "defaults"} |%{$_.Values} | Select-Object -First 1;
    if (!$defaults) {$defaults = @{}}

    function Add-PropertyValue($object, $name, $value)
    {
        Add-Member -InputObject $object -MemberType NoteProperty -Name $name -Value ''
        $object.$name = $value
    }

    function Add-Property($object, $name, [hashtable]$defaults, [Parameter(ValueFromRemainingArguments = $true)] [object[]]$values)
    {
        if ($defaults.Contains($name)) { $values = $values[0], $defaults.Get_Item($name), $values[1 .. ($values.Length - 1)]}

        $value = $values | Where-Object { !($_ -eq $null) -and !($_ -eq '')} | Select-Object -first 1
        Add-PropertyValue $object $name $value
    }

    function Locate-NuGetExe()
    {
        if ($NuGetExe -and (Test-Path $NuGetExe)) { return $NuGetExe; }
        if ($defaults.Contains("NuGetExe")) { return $defaults["NuGetExe"]; }
        if (Test-Path '.tools\NuGet.exe') { return '.tools\NuGet.exe' }
        if (Test-Path '.nuget\NuGet.exe') { return '.nuget\NuGet.exe' }
        if (Test-Path '.\NuGet.exe') { return '.\NuGet.exe' }

        $path = Which-Command "NuGet.exe" -ThrowOnNotFound $false
        if ($path) { return $path}
        return $null
    }

    function Get-NuGetExe($downloadUri, $toolsPath)
    {
        $path = Locate-NuGetExe;
        if ($path)
        {
            Write-ShortStatus "Using NuGet.exe from $path";
            return $path;
        }

        $nugetPath = "$toolsPath\NuGet.exe"
        Write-ShortStatus "Fetching NuGet.exe from $downloadUri to $nugetPath..."
        mkdir $toolsPath -Force | Out-Null
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest $downloadUri -OutFile $nugetPath
        return $nugetPath
    }

    function Locate-NuGetConfig()
    {
        if (Test-Path '.nuget\NuGet.Config') { return '.nuget\NuGet.Config' }
        return $null
    }

    function Construct-NuGetArgs($cfg)
    {
        $args = @()
        if ($cfg.NuGetSource) { $args += "-Source"; $args += $cfg.NuGetSource; }
        if ($cfg.NuGetConfig) { $args += "-ConfigFile"; $args += $cfg.NuGetConfig; }
        return $args
    }

    $object = New-Object PSObject

    if ($AdditionalParams)
    {
        $AdditionalParams | % { $p = $_ -split ':', 2; Add-Property $object $p[0] $defaults $(if ($p.Length -eq 2) { $p[1] } else { $true })}
    }

    Add-PropertyValue $object 'ToolsPath' '.tools'
    Add-Property $object 'NuGetExeDownloadUri' $defaults ("https://dist.nuget.org/win-x86-commandline/latest/nuget.exe")
    Add-Property $object 'Target' $defaults $Target
    Add-Property $object 'AnsiConsole' $defaults if($AnsiConsole.IsPresent) { $AnsiConsole} else { $null }
    Add-PropertyValue $object 'NuGetExe' $(Get-NuGetExe $object.NuGetExeDownloadUri $object.ToolsPath)
    Add-Property $object 'NuGetSource' $defaults $NuGetSource
    Add-Property $object 'NuGetConfig' $defaults $NuGetConfig $(Locate-NuGetConfig)
    Add-PropertyValue $object 'NuGetArgs' $(Construct-NuGetArgs $object)

    # Hide all parameters
    $PSBoundParameters.GetEnumerator() | % { set-variable -name $_.Key -Option private -ErrorAction SilentlyContinue}
    return $object
}

function private:Execute-Steps([array]$makefile)
{
    function Should-RunStep($step)
    {
        return ($Context.Target -and ($step.Target -contains $Context.Target)) -or ($RunSteps -and ($RunSteps -contains $name));
    }

    Write-Header "Executing steps for target: $($Context.Target)..."
    if ($RunSteps) { Write-Status "Only executing specified steps: $($RunSteps -join ", ")" }

    [array]$steps = $makefile | Where-Object { Should-RunStep $_ }

    if (!$steps) { throw 'No matching steps have been found!' }

    for ($i = 0; $i -lt $steps.Length; $i++) { Write-Host "$($i+1). $($steps[$i].Name)" }

    $Tools.Keys | % { New-Variable -Name $_ -Value $Tools[$_] }

    for ($i = 0; $i -lt $steps.Length; $i++)
    {
        # todo: rethink
        Write-Header -style "*" -header "$($i+1)/$($steps.Length): $($steps[$i].Name)..."
        $sw = [Diagnostics.Stopwatch]::StartNew()
        & ($steps[$i].Body)
        if (-not $?) { throw 'Last step terminated with error...' }
        $sw.Stop()
        Write-ShortStatus "$($steps[$i].Name) run duration: $($sw.Elapsed)"
    }
}

function private:Restore-Packages($makefile)
{
    mkdir $Context.ToolsPath -Force | Out-Null
    [array]$packages = $makefile | Where-Object {($_.Type -eq 'module') -or ($_.Type -eq 'tool')};
    if (!$packages) {return; }

    Write-Header "Restoring dependencies..."
    $content = @('<?xml version="1.0" encoding="utf-8"?>', '<packages>')
    $packages | % {$content += "<package id=""$($_.Package)"" version=""$($_.Version)"" />"};
    $content += '</packages>';
    $packagesConfig = $Context.ToolsPath + "\packages.config";
    Set-Content $packagesConfig -Value ($content -join "`r`n" ) -Encoding UTF8

    Invoke-Nuget restore $packagesConfig -OutputDirectory $Context.ToolsPath
}

function private:Load-Modules($coreVersion, $makefile)
{
    Write-Status "Loading modules..."
    function Fetch-Module ($name, $version)
    {
        $path = Fetch-Package $name $version
        $file = "$path\$name.ps1"
        if (!(Test-Path $file)) { Write-Error "Invalid module: unable to locate entry point: $file"}

        return Create-Object @{Name = $name; File = $file; Version = $version}
    }

    $core = Create-Object @{Name = 'psmake.core'; File = "$PSScriptRoot\ext\psmake.core.ps1"; Version = $coreVersion}
    $modules = @{ $core.Name = $core }
    $makefile | Where-Object {$_.Type -eq 'module'} | % {Fetch-Module $_.Package $_.Version} | % { $modules.Add($_.Name, $_) }
    return $modules
}

function private:Load-Tools($makefile)
{
    Write-Status "Loading tools..."
    function Fetch-Tool($tool){
        $path = Fetch-Package $tool.Package $tool.Version
        $fileInfo =  Get-ChildItem -Path $path -Filter $tool.Path -Recurse | Select-Object -First 1;
        if(!$fileInfo){throw "No matching tool '$($tool.Path)' has been found in '$path'"}
        return $fileInfo.FullName;
    }

    $tools = @{}
    $makefile | Where-Object {$_.Type -eq 'tool'} | % {
        $path = Fetch-Tool $_
        $tools.Add($_.Name, $path);
        Write-ShortStatus "Loaded `$$($_.Name) = '$path'"
    }

    return $tools
}

$overall_sw = [Diagnostics.Stopwatch]::StartNew()
try
{
    $ErrorActionPreference = 'Stop'
    if ($AnsiConsole) {. $PSScriptRoot\ext\psmake.ansi.ps1}
    . $PSScriptRoot\ext\psmake.core.ps1

    $private:makeFile = Load-MakeFile
    $Context = Build-Context

    if ($GetVersion) { Get-Version }
    else
    {
        Restore-Packages $makefile
        $Modules = (Load-Modules Get-Version $makefile)
        $Tools = (Load-Tools $makefile)
        Execute-Steps $private:makeFile

        Write-Host -ForegroundColor 'Green' "Make finished :)"
    }
}
catch [Exception]
{
    $_.Exception | format-list -force | Out-String | Write-Host -ForegroundColor 'DarkRed'
    $_.InvocationInfo |Format-List | Out-String | Write-Host -ForegroundColor 'DarkRed'
    Write-Host -ForegroundColor 'Red' "Make failed :("
    throw
}
finally
{
    $overall_sw.Stop()
    Write-ShortStatus "PsMake run duration: $($overall_sw.Elapsed)"
    if ($AnsiConsole) { remove-item function:Write-Host }
}
