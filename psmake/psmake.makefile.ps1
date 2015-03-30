function Define-Step($name, $body, $target)
{
	$object = New-Object PSObject
	Add-Member -InputObject $object -MemberType NoteProperty -Name Name -Value ""
	Add-Member -InputObject $object -MemberType NoteProperty -Name Target -Value ""
	Add-Member -InputObject $object -MemberType NoteProperty -Name Body -Value ""
	 
	$object.Name = $name
	$object.Target=$target -split ","
	$object.Body=$body

	Write-Output $object
}