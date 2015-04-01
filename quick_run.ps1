rmdir temp -force -recurse -ErrorAction SilentlyContinue
& .\packageAll.ps1
& .\psmake\psmake.ps1 -Scaffold empty -md temp -NuGetSource $PSScriptRoot
& .\temp\make.ps1 -Target build