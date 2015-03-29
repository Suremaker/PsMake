function Write-Host
{
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkID=113426', RemotingCapability='None')]
    param(
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromRemainingArguments=$true)]
        [System.Object]
        ${Object},

        [switch]
        ${NoNewline},

        [System.Object]
        ${Separator},

        [System.ConsoleColor]
        ${ForegroundColor},

        [System.ConsoleColor]
        ${BackgroundColor})

    begin
    {
		function EscapeFgColor($color)
		{
			$colorCode = switch ($color) {
				'Black' {'0;30'}
				'DarkBlue' {'0;34'}
				'DarkGreen' {'0;32'}
				'DarkCyan' {'0;36'}
				'DarkRed' {'0;31'}
				'DarkMagenta' {'0;35'}
				'DarkYellow' {'0;33'}
				'Gray' {'0;37'}
				'DarkGray' {'1;30'}
				'Blue' {'1;34'}
				'Green' {'1;32'}
				'Cyan' {'1;36'}
				'Red' {'1;31'}
				'Magenta' {'1;35'}
				'Yellow' {'1;33'}
				'White' {'1;37'}
				default { $null }
			}
			if (!$colorCode) { return $null }
			return "[$($colorCode)m"
		}
			
        try {
			$newLine = !$NoNewline
			$PSBoundParameters.Remove('NoNewLine') | Out-Null
			$PSBoundParameters.NoNewLine = $true

            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand(
                    'Microsoft.PowerShell.Utility\Write-Host', 
                    [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {& $wrappedCmd @PSBoundParameters }
            
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)

			[string]$fg = EscapeFgColor($ForegroundColor)
        } catch {
            throw
        }
    }

    process
    {
        try {
			if($fg) { [Console]::Write([char]27); [Console]::Write($fg); }
            $steppablePipeline.Process($_)
			if($fg) { [Console]::Write([char]27); [Console]::Write("[0m"); }
			if ($newLine) { & $wrappedCmd }
        } catch {
            throw
        }
    }

    end
    {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
    <#

    .ForwardHelpTargetName Write-Host
    .ForwardHelpCategory Cmdlet

    #>
}