<#
.SYNOPSIS
    Used to invoke the Start-Sleep command with a duration based on the provided [RetryMultiplier] and [RetryCount] values.
.DESCRIPTION
    The Wait-PSRetryDelay function parses the provided [RetryMultiplier] (optional) and [RetryCount] values to Get-PSRetryDelay, and uses the returned retry delay time to set the time to sleep for.

    By default, the function will use a fixed retry delay time based on the [RetryMultiplier].

    To simplify use, a default value is provided for the [RetryMultiplier] (2). This value can also be specified at invocation.

    To provide additional control over the retry logic, this function can operate in 3 modes:
      - Fixed (default) : Retry using a fixed time period, as specified by -RetryMultiplier (Alias = RetryDelay)
      - Linear          : Retry using a linear backoff, calculated as the multiple of -RetryMultiplier and the -RetryCount value
      - Exponential     : Retry using an exponential backoff, calculated as the RetryCount value to the power of the -RetryMultiplier value

    This function also supports providing a custom message to indicate why the retry delay is being invoked. By default this will be written to the Verbose log stream, but can be set to warning using the [Warning] switch.
.EXAMPLE
    Wait-PSRetryDelay -RetryCount 3

    Runs command with default settings, invoking a wait time of 2 seconds
.EXAMPLE
    Wait-PSRetryDelay -RetryCount 3 -Warning
    WARNING: Starting retry delay with fixed wait duration [count=3] [wait=2s]

    Runs command with default settings, invoking a wait time of 2 seconds and displaying a warning
.EXAMPLE
    Wait-PSRetryDelay -RetryCount 3 -Message "An exception was caught running the command." -Warning
    WARNING: An exception was caught running the command. Starting retry delay with fixed wait duration [count=3] [wait=2s]

    Runs command with default settings, invoking a wait time of 2 seconds and displaying a warning with custom message
.EXAMPLE
    3 | Wait-PSRetryDelay
    2

    Runs command with default settings using pipeline input, invoking a wait time of 2 seconds
.EXAMPLE
    Wait-PSRetryDelay -RetryMultiplier 5 -RetryCount 3 -Linear

    Runs command with custom multiplier and linear back-off, invoking a wait time of 15 seconds
.EXAMPLE
    Wait-PSRetryDelay -RetryMultiplier 2 -RetryCount 6 -Exponential

    Runs command with custom multiplier and exponential back-off, invoking a wait time of 64 seconds
#>
function Wait-PSRetryDelay {
    [CmdletBinding(PositionalBinding = $true)]
    param (
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'Fixed')]
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'Linear')]
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = 'Exponential')]
        [Alias("RetryDelay")]
        [int]$RetryMultiplier = 2,
        [Parameter(Mandatory = $true, ValueFromPipeline, Position = 1, ParameterSetName = 'Fixed')]
        [Parameter(Mandatory = $true, ValueFromPipeline, Position = 1, ParameterSetName = 'Linear')]
        [Parameter(Mandatory = $true, ValueFromPipeline, Position = 1, ParameterSetName = 'Exponential')]
        [int]$RetryCount,
        [Parameter(Mandatory = $false, ParameterSetName = 'Fixed')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Linear')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Exponential')]
        [string]$Message,
        [Parameter(Mandatory = $false, ParameterSetName = 'Fixed')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Linear')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Exponential')]
        [switch]$Warning,
        [Parameter(Mandatory = $true, ParameterSetName = 'Fixed')]
        [switch]$Linear,
        [Parameter(Mandatory = $true, ParameterSetName = 'Exponential')]
        [switch]$Exponential
    )
    # Use begin block to validate input parameters (fail fast)
    # and set mode once
    begin {
        # Need to set ModeMessage and ModeParam depending on operating mode
        if ($Exponential) {
            $ModeMessage = "exponential backoff"
            $ModeParam = @{
                Exponential = $true
            }
        }
        elseif ($Linear) {
            $ModeMessage = "linear backoff"
            $ModeParam = @{
                Linear = $true
            }
        }
        else {
            $ModeMessage = "fixed wait duration"
            $ModeParam = @{}
        }
    }
    # Use process block to get the required retry delay time and use this to
    # set the Start-Sleep duration.
    process {
        $RetryDelayTime = $RetryCount | Get-PSRetryDelay $RetryMultiplier @ModeParam
        $RetryMessage = "Starting retry delay with $($ModeMessage) [count=$($RetryCount)] [wait=$($RetryDelayTime)s]"
        if ($Message) {
            $RetryMessage = "$Message $RetryMessage"
        }
        if ($Warning) {
            Write-Warning $RetryMessage
        }
        else {
            Write-Verbose $RetryMessage
        }
        $RetryDelayTime | Start-Sleep
    }
}
