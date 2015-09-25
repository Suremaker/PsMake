function Create-DefaultsFile()
{
    $file = "$($Context.MakeDirectory)\Defaults.ps1"
	$defaults=@{}
	if($Context.NuGetSource) { $defaults.Add('NuGetSource', $Context.NuGetSource) }
	if($Context.NuGetConfig) { $defaults.Add('NuGetConfig', $Context.NuGetConfig) }
	$defaults = ($defaults.GetEnumerator() | %{ "`t'$($_.Key)' = '$($_.Value)'"}) -join ";`r`n"
	Set-Content $file "Write-Output @{`r`n$defaults`r`n}"
}

function Create-MakefileFile()
{
    Write-Host "Creating Makefile.ps1..."
    $file = "$($Context.MakeDirectory)\Makefile.ps1"

    Set-Content $file @"
Define-Step -Name 'Step one' -Target 'build' -Body {
`techo 'Greetings from step one'
}

Define-Step -Name 'Step two' -Target 'build,deploy' -Body {
`techo 'Greetings from step two'
}
"@

}

function Create-MakeFile($psmakeVersion)
{
    Write-Host "Creating make.ps1..."
    $nuArgs=if($Context.NuGetConfig) { "-ConfigFile $($Context.NuGetConfig)"} else { '' } 
    $cmd = "$($Context.NuGetExe) install psmake -Version $psmakeVersion -OutputDirectory $($Context.MakeDirectory)\psmake $nuArgs"  
    $file = "$($Context.MakeDirectory)\make.ps1"
	$nugetSrc = if ($Context.NuGetSource) { "'$($Context.NuGetSource)'" } else { '$null' }
	
	$content = @"
`$private:PsMakeVer = '$psmakeVersion'
`$private:PsMakeNugetSource = $nugetSrc

function private:Get-NuGetArgs (`$params, `$defaultSource)
{
	function private:Find-Arg(`$array, `$name, `$default) { 
		`$idx = [array]::IndexOf(`$array, `$name)
		if( (`$idx -gt -1) -and (`$idx+1 -lt `$array.Length)) { return `$array[`$idx+1] }
		return `$default
	}
	`$nuGetSource = Find-Arg `$params '-NuGetSource' `$defaultSource
	if (`$nuGetSource) { return '-Source', `$nuGetSource}
	return @()
}

`$private:srcArgs = Get-NuGetArgs `$args `$PsMakeNugetSource
$($Context.NuGetExe) install psmake -Version `$PsMakeVer -OutputDirectory $($Context.MakeDirectory) $nuArgs @srcArgs
& `"$($Context.MakeDirectory)\psmake.`$PsMakeVer\psmake.ps1`" -md $($Context.MakeDirectory) @args
"@
	
    Set-Content $file $content
}

function Scaffold-Empty($psmakeVersion)
{
    Write-Host "Creating $($Context.MakeDirectory)..."
    mkdir $Context.MakeDirectory -ErrorAction SilentlyContinue | Out-Null
    
    Create-MakeFile $psmakeVersion
    Create-MakefileFile
    Create-DefaultsFile
}

function Scaffold-Project($type, $psmakeVersion)
{
    Write-Host "Scaffolding project type: $type"
    switch ($type) {
        'empty' { Scaffold-Empty $psmakeVersion }
    }
}