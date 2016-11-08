
return new-object psobject `
| Add-Member -PassThru -MemberType ScriptMethod -Name InstallPackage -Value {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $Name,
        [Parameter(Mandatory=$true, Position=1)]
        $Version,
        [Parameter(Mandatory=$true, Position=2)]
        $Destination
    )

    $nuArgs = $Context.NuGetArgs
    call $Context.NugetExe install $Name -Version $Version -OutputDirectory $Destination -NonInteractive -Verbosity detailed @nuArgs
} `
| Add-Member -PassThru -MemberType ScriptMethod -Name FindPackage -Value {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $Name
    )

    $nuArgs = $Context.NuGetArgs
    $result = & $Context.NuGetExe list $Name -NonInteractive @nuArgs

    $modules = @{}
    $result | % { 
		$p = $_ -split ' '; 
		if ($p[1] -match '^[0-9]+(\.[0-9]+){0,3}$') { $modules.Add($p[0],$p[1]) }
	}
	return $modules
}