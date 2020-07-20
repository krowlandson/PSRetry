<#
.SYNOPSIS
    Used to return a retry delay time based on the provided [RetryMultiplier] and [RetryCount] values.
.DESCRIPTION
    The Get-PSRetryDelay function evaluates the provided [RetryMultiplier] (optional) and [RetryCount] values and returns the expected retry delay time to use.

    By default, the function will return a fixed retry delay time based on the [RetryMultiplier].

    To simplify use, a default value is provided for the [RetryMultiplier] (2). This value can also be specified at invocation.

    To provide additional control over the retry logic, this function can operate in 3 modes:
      - Fixed (default) : Retry using a fixed time period, as specified by -RetryMultiplier (Alias = RetryDelay)
      - Linear          : Retry using a linear backoff, calculated as the multiple of -RetryMultiplier and the -RetryCount value
      - Exponential     : Retry using an exponential backoff, calculated as the RetryCount value to the power of the -RetryMultiplier value
.EXAMPLE
    Get-PSRetryDelay -RetryCount 3
    2

    Runs command with default settings
.EXAMPLE
    3 | Get-PSRetryDelay
    2

    Runs command with default settings using pipeline input
.EXAMPLE
    Get-PSRetryDelay -RetryMultiplier 5 -RetryCount 3 -Linear
    15

    Runs command with custom multiplier and linear back-off
.EXAMPLE
    Get-PSRetryDelay -RetryMultiplier 2 -RetryCount 6 -Exponential
    64

    Runs command with custom multiplier and exponential back-off
#>
function Get-PSRetryDelay {
    [CmdletBinding(PositionalBinding = $true)]
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $false, Position=0, ParameterSetName = 'Fixed')]
        [Parameter(Mandatory = $false, Position=0, ParameterSetName = 'Linear')]
        [Parameter(Mandatory = $false, Position=0, ParameterSetName = 'Exponential')]
        [Alias("RetryDelay")]
        [int]$RetryMultiplier = 2,
        [Parameter(Mandatory = $true, ValueFromPipeline, Position=1, ParameterSetName = 'Fixed')]
        [Parameter(Mandatory = $true, ValueFromPipeline, Position=1, ParameterSetName = 'Linear')]
        [Parameter(Mandatory = $true, ValueFromPipeline, Position=1, ParameterSetName = 'Exponential')]
        [int]$RetryCount,
        [Parameter(Mandatory = $true, ParameterSetName = 'Fixed')]
        [switch]$Linear,
        [Parameter(Mandatory = $true, ParameterSetName = 'Exponential')]
        [switch]$Exponential
    )
    # Use begin block to validate input parameters (fail fast)
    begin {
        $MinimumRetryMultiplierWithExponential = 2
        if ($Exponential -and $RetryMultiplier -lt $MinimumRetryMultiplierWithExponential) {
            Write-Error "The provided value [$RetryMultiplier] is less than the minimum required value [$MinimumRetryMultiplierWithExponential] for -RetryMultiplier when using -Exponential."
            exit
        }
    }
    # Use process block to get the calculate and return the retry delay time
    process {
        if ($Exponential) {
            return [int][math]::Pow($RetryMultiplier, $RetryCount)
        }
        elseif ($Linear) {
            return [int][math]::BigMul($RetryMultiplier, $RetryCount)
        }
        else {
            return [int]$RetryMultiplier
        }
    }
}
