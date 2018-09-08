function Define-Step($name, $body, $target)
{
	Write-Output Create-Object @{ Type="step"; Name=$name; Target=$target -split ","; Body=$body}
}

function Require-Module($package, $version)
{
	Write-Output Create-Object @{ Type="module"; Package=$package; Version=$version}
}

function Define-Defaults([hashtable]$defaults)
{
	Write-Output Create-Object @{Type="defaults"; Values=$defaults;}
}
