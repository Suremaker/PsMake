Write-Host "Packaging all modules..."

Get-ChildItem . -filter "*.nuspec" -recurse | Foreach {
	$nuspec = $_.fullname
	Write-Host "Packing $nuspec"
	
	$dirName = Split-Path $nuspec -Parent
	[xml] $packageMeta = Get-Content $nuspec
	$packageName = $packageMeta.package.metadata.id
	$entryPoint = "$dirName\$packageName.ps1"
	if (!(Test-Path $entryPoint))
	{
		throw "No entry name has been found for $nuspec.`n Ensure that $entryPoint exists!"
	}
	
	.nuget\\NuGet.exe pack $nuspec -NoPackageAnalysis
}