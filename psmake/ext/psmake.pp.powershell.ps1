#Requires -Version 5.0

function Convert-ToSplatHashTable([string[]] $splatArray) {
	$result = @{}
	for($i=1;$i -lt $splatArray.Length;$i = $i+2) { $result.Add($splatArray[$i-1].trimstart('-'),$splatArray[$i]); }
	return $result;
}

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

    $nuArgs = Convert-ToSplatHashTable $Context.NuGetArgs
    Install-Package -Name $Name -RequiredVersion $Version -Destination $Destination -ProviderName NuGet @nuArgs -Force | Out-Null
} `
| Add-Member -PassThru -MemberType ScriptMethod -Name FindPackage -Value {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        $Name
    )

    $nuArgs = Convert-ToSplatHashTable $Context.NuGetArgs
	Write-Host Find-Package -Name $Name -ProviderName NuGet @nuArgs
    $result = Find-Package -Name $Name -ProviderName NuGet @nuArgs

    $modules = @{}
    $result | % { 
		$p = $_ -split ' '; 
		if ($p[1] -match '^[0-9]+(\.[0-9]+){0,3}$') { $modules.Add($_.Name,$_.Version) }
	}
	return $modules
}