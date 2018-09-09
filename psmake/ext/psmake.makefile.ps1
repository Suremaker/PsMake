function Define-Step($name, $body, $target)
{
	Write-Output Create-Object @{ Type="step"; Name=$name; Target=$target -split ","; Body=$body}
}

function Require-Module($package, $version)
{
	Write-Output Create-Object @{ Type="module"; Package=$package; Version=$version}
}

function Require-Tool($package, $version, $path, $named=$null)
{
	if (!$named){$named = $package -replace '[^a-zA-Z_]',''}
	if($named -notmatch '^[a-zA-Z_]+$'){throw "Tool '$package' name '$named' is not a valid variable name."}

	Write-Output Create-Object @{ Type="tool"; Package=$package; Version=$version; Path=$path; Name=$named}
}

function Define-Defaults([hashtable]$defaults)
{
	Write-Output Create-Object @{Type="defaults"; Values=$defaults;}
}
