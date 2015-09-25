function Read-Modules()
{
    Write-Host "Reading modules..."
    $path = "$($Context.MakeDirectory)\Modules.ps1"
    if (!(Test-Path $path))
	{
		Write-Host "$path does not exist, skipping..."
		return @{}
	}

	return & $path
}

function Fetch-Module ($name,$version)
{
    $path = Fetch-Package $name $version
    $file="$path\$name.ps1"
    if(!(Test-Path $file)) { Write-Error "Invalid module: unable to locate entry point: $file"}

    return Create-Object @{Name=$name; File=$file; Version=$version}
}

function Fetch-Modules()
{
    return $(Read-Modules).GetEnumerator() | %{ return Fetch-Module $_.Key $_.Value }
}

function List-Modules($showIdOnly = $false)
{
    $modules = Read-Modules
	if ($showIdOnly) { return $modules.Keys } 
	return $modules
}

function Write-Modules($modules)
{
    $content = "Write-Output @{`n"
    $modules.GetEnumerator() | % { $content+= "`t'$($_.Key)' = '$($_.Value)';`n"}
    $content += '}'

    Set-Content "$($Context.MakeDirectory)\Modules.ps1" $content
}

function Add-Module([string]$name,[string]$version)
{
    Write-Host "Adding module $name=$version..."

    if(!($name.StartsWith('psmake.mod.'))) { Write-Error "Invalid module name $name. A proper module name has to start with: psmake.mod."}
    [hashtable]$modules = Read-Modules
    if($modules.ContainsKey($name)) { Write-Error "Module $name is already added." }
    Fetch-Module $name $version | Out-Null
    $modules.Add($name,$version)

    Write-Modules $modules
}

function List-AvailableModules($showIdOnly = $false)
{
    Write-Host "Listing available modules..."
    $args = $Context.NuGetArgs
    $result = & $Context.NuGetExe list psmake.mod. -NonInteractive @args

    $modules = @{}
    $result | % { 
		$p = $_ -split ' '; 
		if ($p[1] -match '^[0-9]+(\.[0-9]+){0,3}$') { $modules.Add($p[0],$p[1]) }
	}
	if ($showIdOnly) { return $modules.Keys } 
    return $modules
}

function Is-VersionHigher([string]$ver1, [string]$ver2)
{
    $v1 = $ver1 -split "\."
    $v2 = $ver2 -split "\."

    for($i=0; $i -lt $v1.Length; $i++)
    {
        [int]$i1 = $v1[$i]
        [int]$i2 = 0
        if ($i -lt $v2.Length) { [int]$i2 = $v2[$i] }
        if ($i1 -gt $i2) { return $true; }
    }
    return $false;
}

function Update-Modules()
{
    [hashtable]$available = List-AvailableModules
    [hashtable]$current = List-Modules

    Write-Host "Updating modules..."
    $current.Clone().GetEnumerator() | % {
        if ($available.Contains($_.Key) -and (Is-VersionHigher $available.Get_Item($_.Key) $_.Value))
        {
            $newVersion = $available.Get_Item($_.Key)
            Write-Host "Updating $($_.Key) ver. $($_.Value) to ver. $newVersion"
            Fetch-Module $_.Key $newVersion | Out-Null
            $current.Set_Item($_.Key, $newVersion)
        }
        else { Write-Host "Module $($_.Key) ver. $($_.Value) is up to date."}
    }

    Write-Modules $current
}