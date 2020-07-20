<#
.SYNOPSIS
    Invokes the provided PowerShell expression within a retry loop.
.DESCRIPTION
    The Invoke-PSRetryExpression function evaluates or runs a specified [string] or [scriptblock] as a command and returns the results of the expression or command.

    This function should be used to improve reliability of commands used in situations where intermittent failures are expected from downstream systems.

    Expressions are evaluated and run in the current scope.

    To simplify use, default values are provided for the -RetryMultiplier (2) and -MaxRetry (5) parameters. These values can also be specified at invocation.

    To provide additional control over the retry logic, this function can operate in 3 modes:
      - Fixed (default) : Retry using a fixed time period, as specified by -RetryMultiplier (Alias = RetryDelay)
      - Linear          : Retry using a linear backoff, calculated as the multiple of -RetryMultiplier and the -RetryCount value
      - Exponential     : Retry using an exponential backoff, calculated as the RetryCount value to the power of the -RetryMultiplier value

    This function also support specifying a list of known errors which can be used to stop the retry loop if found. These can be used to either generate a warning (-ContinueOnErrors) or throw an error (-StopOnErrors) depending on the desired outcome.
.EXAMPLE
    Invoke-PSRetryExpression -Command { Invoke-RestMethod -Uri "https://www.microsoft.com" }

    Run command with default settings
.EXAMPLE
    Invoke-PSRetryExpression -Command { Invoke-RestMethod -Uri "https://www.microsoft.com" } -RetryDelay 5 -Linear

    Run command with linear backoff and custom RetryDelay
.EXAMPLE
    Invoke-PSRetryExpression -Command { Invoke-RestMethod -Uri "https://www.microsoft.com" } -Exponential

    Run command with exponential backoff and default settings
.EXAMPLE
    Invoke-PSRetryExpression -Command { Invoke-RestMethod -Uri "https://www.microsoft.com" } -ContinueOnErrors "404", "500"

    Run command with default settings, fail fast and Write-Warning for known errors
.EXAMPLE
    Invoke-PSRetryExpression -Command { Invoke-RestMethod -Uri "https://www.microsoft.com" } -StopOnErrors "404", "500"

    Run command with default settings, fail fast and throw error for known errors
.INPUTS
    None
.OUTPUTS
    Returns the result of the specified Command
#>
function Invoke-PSRetryExpression {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline, Position = 0, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $true, ValueFromPipeline, Position = 0, ParameterSetName = 'Linear')]
        [Parameter(Mandatory = $true, ValueFromPipeline, Position = 0, ParameterSetName = 'Exponential')]
        [Alias("C")]
        [scriptblock]$Command,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Linear')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Exponential')]
        [string[]]$ContinueOnErrors,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Linear')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Exponential')]
        [string[]]$StopOnErrors,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Linear')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Exponential')]
        [Alias("RetryDelay")]
        [int]$RetryMultiplier = 2,

        [Parameter(Mandatory = $false, ParameterSetName = 'Default')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Linear')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Exponential')]
        [int]$MaxRetry = 5,

        [Parameter(Mandatory = $true, ParameterSetName = 'Linear')]
        [switch]$Linear,

        [Parameter(Mandatory = $true, ParameterSetName = 'Exponential')]
        [switch]$Exponential
    )

    begin {

        [regex]$regex_RemoveErrorHandling = "(?i)(-Error(Action|Variable)) ('|`")?\w+('|`")?"

        # Need to set ModeMessage and ModeParam depending on operating mode
        if ($Exponential) {
            $ModeParam = @{
                Exponential = $true
            }
        }
        elseif ($Linear) {
            $ModeParam = @{
                Linear = $true
            }
        }
        else {
            $ModeParam = @{}
        }

    }

    process {
        $RetryCount = 0
        $EndLoop = $false
        $Test_Command_Error_Handling = $regex_RemoveErrorHandling.Matches($Command)
        if ($Test_Command_Error_Handling) {
            Write-Warning "Found error handling in command. Removing value(s) [$($Test_Command_Error_Handling.Value -join "] [")] to ensure correct operation of retry loop."
        }
        do {
            try {
                $RetryCount++
                $Output = Invoke-Expression -Command "$($regex_RemoveErrorHandling.Replace($Command,'')) -ErrorAction Stop"
                $EndLoop = $true
            }
            catch {
                # Throw if the error message matches one provided in the parameter StopOnErrors
                if ($_ -in $StopOnErrors) {
                    throw
                }
                # Skip retry if the error message matches one provided in the parameter ContinueOnErrors
                elseif ($_ -in $ContinueOnErrors) {
                    Write-Warning $_
                    $EndLoop = $true
                }
                # Retry command if within MaxRetry threshold
                elseif ($RetryCount -le $MaxRetry) {
                    Wait-PSRetryDelay $RetryMultiplier $RetryCount -Message "Caught Error: $_." -Warning @ModeParam
                }
                # Once all retries have completed, throw error
                else {
                    throw
                }
            }
        } until ($EndLoop)

        if ($Output) {
            return $Output
        }

    }

}
