param([Parameter(Mandatory=$true)][string]$App, [Parameter(Mandatory=$true)][string]$Output)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
if (Test-Path $Output) { throw 'Use a fresh output directory.' }
New-Item -ItemType Directory $Output | Out-Null
$Output = (Resolve-Path $Output).Path
$App = (Resolve-Path $App).Path
$assembly = Join-Path (Split-Path $App) 'eSemnBun.dll'
$marker = [BitConverter]::ToString([Text.Encoding]::Unicode.GetBytes('MSIGN_TEST_PREFERENCES'))
if (-not (Test-Path $assembly) -or -not [BitConverter]::ToString([IO.File]::ReadAllBytes($assembly)).Contains($marker)) {
    throw 'A Debug app with isolated preference support is required.'
}
$names = @('MSIGN_DEMO_CARDS','MSIGN_DEMO_PAGE','MSIGN_DEMO_VERIFY','MSIGN_SCREENSHOT_CAPTURE','MSIGN_TEST_PREFERENCES')
$before = @{}; foreach ($name in $names) { $before[$name] = [Environment]::GetEnvironmentVariable($name) }
[xml]$resource = Get-Content (Join-Path $PSScriptRoot '../src/MoldSign.App/Strings/en-US/Resources.resw') -Raw
$strings = @{}; foreach ($entry in $resource.root.data) { $strings[$entry.name] = [string]$entry.value }
$results = @()
function Find-Visible($id, $process) {
    $condition = [System.Windows.Automation.AndCondition]::new(
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::ProcessIdProperty,$process.Id),
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::AutomationIdProperty,$id))
    foreach ($node in [System.Windows.Automation.AutomationElement]::RootElement.FindAll([System.Windows.Automation.TreeScope]::Descendants,$condition)) {
        if ($node.Current.IsOffscreen) {
            $scroll = $null
            if ($node.TryGetCurrentPattern([System.Windows.Automation.ScrollItemPattern]::Pattern, [ref]$scroll)) { $scroll.ScrollIntoView() }
            else {
                $parent = [System.Windows.Automation.TreeWalker]::ControlViewWalker.GetParent($node)
                while ($parent -and $parent.Current.ProcessId -eq $process.Id) {
                    if ($parent.TryGetCurrentPattern([System.Windows.Automation.ScrollPattern]::Pattern, [ref]$scroll) -and $scroll.Current.VerticallyScrollable) {
                        $direction = if ($node.Current.BoundingRectangle.Top -lt $parent.Current.BoundingRectangle.Top) {
                            [System.Windows.Automation.ScrollAmount]::SmallDecrement
                        } else { [System.Windows.Automation.ScrollAmount]::SmallIncrement }
                        $scroll.Scroll([System.Windows.Automation.ScrollAmount]::NoAmount, $direction)
                        break
                    }
                    $parent = [System.Windows.Automation.TreeWalker]::ControlViewWalker.GetParent($parent)
                }
            }
        }
        if (-not $node.Current.IsOffscreen) { return $node }
    }
    return $null
}
function Wait-Element($id, $process) {
    $deadline = [DateTime]::UtcNow.AddSeconds(25)
    while ([DateTime]::UtcNow -lt $deadline) {
        if ($process.HasExited) { throw 'Application exited before assertions completed.' }
        $node = Find-Visible $id $process
        if ($node) { return $node }
        Start-Sleep -Milliseconds 100
    }
    throw "Missing UI element: $id"
}
function Invoke-Element($node) { $node.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern).Invoke() }
try {
    if (Get-Process eSemnBun -ErrorAction SilentlyContinue) { throw 'Close eSemnBun before running the isolated desktop suite.' }
    foreach ($state in @('valid','invalid','unknown','unsigned')) {
        $work = Join-Path $Output $state
        New-Item -ItemType Directory $work | Out-Null
        $env:MSIGN_TEST_PREFERENCES = Join-Path $work 'settings.json'
        @{Language='en-US';BridgeEnabled=$false;DemoModeEnabled=$true} | ConvertTo-Json | Set-Content $env:MSIGN_TEST_PREFERENCES
        $env:MSIGN_DEMO_CARDS='2'; $env:MSIGN_DEMO_PAGE='verify'
        $env:MSIGN_DEMO_VERIFY=$state; $env:MSIGN_SCREENSHOT_CAPTURE='1'
        $process = Start-Process $App -PassThru -WorkingDirectory (Split-Path $App)
        try {
            $null = Wait-Element 'VerifyPageTitle' $process
            Invoke-Element (Wait-Element 'ChooseDocuments' $process)
            $outcome = Wait-Element 'VerificationOutcome' $process
            $key = @{valid='Verdict_Valid';invalid='Verdict_Invalid';unknown='Verdict_Unknown';unsigned='Verdict_Unsigned'}[$state]
            $deadline = [DateTime]::UtcNow.AddSeconds(10)
            while ($outcome.Current.Name -ne $strings[$key] -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 100 }
            if ($outcome.Current.Name -ne $strings[$key]) { throw "Wrong verdict for $state" }
            if ($state -ne 'unsigned') {
                foreach ($id in @('VerifyCertificateDetails','VerifyTechnicalDetails')) {
                    $node = Wait-Element $id $process
                    $pattern = $node.GetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern)
                    $pattern.Expand()
                    $deadline = [DateTime]::UtcNow.AddSeconds(5)
                    while ($pattern.Current.ExpandCollapseState -ne [System.Windows.Automation.ExpandCollapseState]::Expanded -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 100 }
                    if ($pattern.Current.ExpandCollapseState -ne [System.Windows.Automation.ExpandCollapseState]::Expanded) { throw "Disclosure did not expand: $id" }
                    $pattern.Collapse()
                    $deadline = [DateTime]::UtcNow.AddSeconds(5)
                    while ($pattern.Current.ExpandCollapseState -ne [System.Windows.Automation.ExpandCollapseState]::Collapsed -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 100 }
                    if ($pattern.Current.ExpandCollapseState -ne [System.Windows.Automation.ExpandCollapseState]::Collapsed) { throw "Disclosure did not collapse: $id" }
                }
            }
            Invoke-Element (Wait-Element 'VerifyClearResults' $process)
            $null = Wait-Element 'ChooseDocuments' $process
            $deadline = [DateTime]::UtcNow.AddSeconds(5)
            while ((Find-Visible 'VerificationOutcome' $process) -and [DateTime]::UtcNow -lt $deadline) { Start-Sleep -Milliseconds 100 }
            if (Find-Visible 'VerificationOutcome' $process) { throw 'Stale outcome after clear' }
            $results += @{scenario=$state;status='passed';action='choose sample, verify, expand/collapse details when signed, clear'}
        } catch {
            $results += @{scenario=$state;status='failed';error=$_.Exception.Message}
            throw
        } finally {
            if (-not $process.HasExited) { Stop-Process -Id $process.Id }
            ConvertTo-Json -InputObject @($results) -Depth 5 | Set-Content (Join-Path $Output 'results.json')
        }
    }
} finally {
    foreach ($name in $names) { [Environment]::SetEnvironmentVariable($name,$before[$name]) }
}
