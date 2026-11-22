# PowerShell can bind $null to an empty string for a .NET string parameter.
# .NET 9+ preserves empty values, so remove absent variables through the provider.
function Set-TestEnvironmentVariable {
    param([string]$Name, [AllowNull()][object]$Value)
    if ($null -eq $Value) {
        Remove-Item -LiteralPath "Env:$Name" -ErrorAction SilentlyContinue
    } else {
        [Environment]::SetEnvironmentVariable($Name, [string]$Value)
    }
}
