[![Build status](https://ci.appveyor.com/api/projects/status/fx4dyiwbxah5xajw/branch/master?svg=true)](https://ci.appveyor.com/project/Suremaker/psmake/branch/master)

# PsMake
A PowerShell based tool which controls a software project build process.

# Quickstart

*Assumptions:* 
* *nuget.exe is on PATH environment variable*
* *Powershell window is opened :)*

#### 1. Install psmake and create an example make structure

Please execute following commands:
```
nuget.exe install psmake -version 3.1.0.0
.\psmake.3.1.0.0\psmake.ps1 -Scaffold empty
ls
```

The output should be similar to this one:
```
D:\tmp> nuget.exe install psmake -version 3.1.0.0
Installing 'psmake 3.1.0.0'.
Successfully installed 'psmake 3.1.0.0'.

D:\tmp> .\psmake.3.1.0.0\psmake.ps1 -Scaffold empty
Scaffolding project type: empty
Creating ....
Creating make.ps1...
Creating Makefile.ps1...

D:\tmp> ls


    Directory: D:\tmp


Mode                LastWriteTime     Length Name
----                -------------     ------ ----
d----        08/04/2015     13:45            psmake.3.1.0.0
-a---        08/04/2015     13:45         22 Defaults.ps1
-a---        08/04/2015     13:45        650 make.ps1
-a---        08/04/2015     13:45        189 Makefile.ps1
```

The current directory would contain a following files:
* Defaults.ps1 - a file with default parameters that would be used during make,
* Makefile.ps1 - a file with all step definitions,
* make.ps1 - a file that performs a make.

*Please note that make.ps1 installs psmake package before run, so it is not needed to include psmake package is sources*

#### 2. Running make
Please execute following commands:
```
PS> .\make.ps1 -Target build
```

The output should be like:
```
D:\tmp> .\make.ps1 -Target build
'psmake 3.1.0.0' already installed.

------------------------------------------------------------
- Loading .\Makefile.ps1...
------------------------------------------------------------

1. Step one
2. Step two

------------------------------------------------------------
- Loading modules
------------------------------------------------------------

Reading modules...
.\Modules.ps1 does not exist, skipping...

------------------------------------------------------------
- Loading environment config...
------------------------------------------------------------

.\Environment.ps1 does not exist, skipping...

------------------------------------------------------------
- Executing steps...
------------------------------------------------------------


************************************************************
* 1/2: Step one...
************************************************************

Greetings from step one

************************************************************
* 2/2: Step two...
************************************************************

Greetings from step two
Make finished :)
```

#### 3. Browsing makefile
Please execute following commands:
```
PS> cat .\Makefile.ps1
```

The output should be like:
```
Define-Step -Name 'Step one' -Target 'build' -Body {
        echo 'Greetings from step one'
}

Define-Step -Name 'Step two' -Target 'build,deploy' -Body {
        echo 'Greetings from step two'
}
```

The makefile.ps1 contains a definition of two steps: `Step one` and `Step two`
Each step has specified list of targets for which it should be executed.
All the steps would be executed in definition order, however a given step would be executed only if it belongs to target specified in `-target` parameter of `make.ps1`.
That is why `.\make.ps1 -Target build` resulted with execution of both steps.

#### 4. More information

The generated `make.ps1` passes all parameters to main psmake script, which means that it accepts all parameters as psmake.

Please execute `PS> Get-Help .\psmake.3.1.0.0\psmake.ps1 -Detailed` to see detailed help and additional examples.

Also please visit [wiki](https://github.com/Suremaker/PsMake/wiki) page for further details.
