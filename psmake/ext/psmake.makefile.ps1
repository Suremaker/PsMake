function Define-Step($name, $body, $target)
{
	Write-Output Create-Object @{ Name=$name; Target=$target -split ","; Body=$body} 
}