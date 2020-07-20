# Invoke-PSRetryExpression

## SYNOPSIS
Invokes the provided PowerShell expression within a retry loop.

## DESCRIPTION
The Invoke-ExpressionWithRetry cmdlet evaluates or runs a specified [string] or [scriptblock] as a command and returns the results of the expression or command.

This cmdlet should be used to improve reliability of commands used in situations where intermittent failures are expected from downstream systems.

Expressions are evaluated and run in the current scope.

To simplify use, default values are provided for the -RetryMultiplier (2) and -MaxRetry (5) parameters. These values can also be specified at invocation.

To provide additional control over the retry logic, this cmdlet can operate in 3 modes:
- Fixed (default) : Retry using a fixed time period, as specified by -RetryMultiplier (Alias = RetryDelay)
- Linear          : Retry using a linear backoff, calculated as the multiple of -RetryMultiplier and the RetryCount value
- Exponential     : Retry using an exponential backoff, calculated as the RetryCount value to the power of the -RetryMultiplier value

This cmdlet also support specifying a list of known errors which can be used to supress the retry loop if found. These can be used to either generate a warning (-ContinueOnErrors) or throw an error (-StopOnErrors) depending on the desired outcome.

## EXAMPLES

### Run command with default settings
```powershell
Invoke-ExpressionWithRetry -Command {Invoke-RestMethod -Uri "https://www.microsoft.com"}
```
### Run command with linear backoff and custom RetryDelay
```powershell
Invoke-ExpressionWithRetry -Command {Invoke-RestMethod -Uri "https://www.microsoft.com"} -RetryDelay 5 -Linear
```
### Run command with exponential backoff and default settings
```powershell
Invoke-ExpressionWithRetry -Command {Invoke-RestMethod -Uri "https://www.microsoft.com"} -Exponential
```
### Run command with default settings, fail fast and Write-Warning for known errors
```powershell
Invoke-ExpressionWithRetry -Command {Invoke-RestMethod -Uri "https://www.microsoft.com"} -ContinueOnErrors "404", "500"
```
### Run command with default settings, fail fast and throw error for known errors
```powershell
Invoke-ExpressionWithRetry -Command {Invoke-RestMethod -Uri "https://www.microsoft.com"} -StopOnErrors "404", "500"
```
