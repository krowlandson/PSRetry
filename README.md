# PSRetry

The PSRetry module provides a a set of PowerShell commands used to simplify adding retry logic to scripts and automation workflow. These functions can be used in any script or automation workflow where reliability needs to be improved, such as when interacting with external providers.

The following functions are currently included in this module:

| Function Name | Description | Documentation |
| ------------- | ----------- | ------------------- |
| [Invoke-PSRetryExpression][Invoke-PSRetryExpression.ps1] | Generic wrapper to easily provide configurable retry logic with multiple back-off options. Can be used around any simple PowerShell command/expression. | [Click here...][Invoke-PSRetryExpression.md]

More functions to follow!

 [//]: # (************************)
 [//]: # (INSERT LINK LABELS BELOW)
 [//]: # (************************)

 [Invoke-PSRetryExpression.md]: ./docs/Invoke-PSRetryExpression.md "Documentation for the Invoke-PSRetryExpression function."
 [Invoke-PSRetryExpression.ps1]: ./functions/Invoke-PSRetryExpression.ps1 "Source code for the Invoke-PSRetryExpression function."
