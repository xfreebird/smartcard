param([Parameter(Mandatory=$true)][string]$App, [Parameter(Mandatory=$true)][string]$Output)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'test-environment.ps1')
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
. (Join-Path $PSScriptRoot 'ui-automation.ps1')
if (Test-Path $Output) { throw 'Use a fresh output directory.' }
New-Item -ItemType Directory $Output | Out-Null
$Output = (Resolve-Path $Output).Path
$App = (Resolve-Path $App).Path
$assembly = Join-Path (Split-Path $App) 'eSemnBun.dll'
$marker = [BitConverter]::ToString([Text.Encoding]::Unicode.GetBytes('MSIGN_UI_TEST_SCENARIO'))
if (-not [BitConverter]::ToString([IO.File]::ReadAllBytes($assembly)).Contains($marker)) { throw 'A Debug scenario-enabled app is required.' }
$runningApps = @(Get-Process eSemnBun -ErrorAction SilentlyContinue | Where-Object { -not $_.HasExited })
if ($runningApps.Count -gt 0) { throw "Close eSemnBun before the isolated suite. Running PIDs: $($runningApps.Id -join ', ')" }
$names = @('MSIGN_TEST_PREFERENCES','MSIGN_DEMO_CARDS','MSIGN_DEMO_PAGE','MSIGN_SCREENSHOT_CAPTURE','MSIGN_UI_TEST_SCENARIO','MSIGN_DEMO_PIN_ONLY')
$before = @{}; foreach ($name in $names) { $before[$name] = [Environment]::GetEnvironmentVariable($name) }
$results = @()
function Elements($id, $process) {
    $condition = [System.Windows.Automation.AndCondition]::new(
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::ProcessIdProperty, $process.Id),
        [System.Windows.Automation.PropertyCondition]::new([System.Windows.Automation.AutomationElement]::AutomationIdProperty, $id))
    return @(Find-AppAutomationElements $process $condition)
}
function Wait-State($message, $process, [scriptblock]$predicate) {
    $deadline = [DateTime]::UtcNow.AddSeconds(25)
    while ([DateTime]::UtcNow -lt $deadline) {
        if ($process.HasExited) { throw 'App exited during journey' }
        if (& $predicate) { return }
        Start-Sleep -Milliseconds 100
    }
    throw "Timed out: $message"
}
# Menus and pages render their items asynchronously: wait until one is on screen before reading it.
function Wait-Element($id, $process) {
    Wait-State $id $process { @(Elements $id $process | Where-Object { -not $_.Current.IsOffscreen }).Count -gt 0 }
    return @(Elements $id $process | Where-Object { -not $_.Current.IsOffscreen })[0]
}
function Click($id, $process) {
    Wait-State $id $process { @(Elements $id $process | Where-Object { -not $_.Current.IsOffscreen -and $_.Current.IsEnabled }).Count -gt 0 }
    $node = @(Elements $id $process | Where-Object { -not $_.Current.IsOffscreen -and $_.Current.IsEnabled })[0]
    $pattern = $null
    if ($node.TryGetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern, [ref]$pattern)) { $pattern.Invoke() }
    elseif ($node.TryGetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern, [ref]$pattern)) { $pattern.Select() }
    elseif ($node.TryGetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern, [ref]$pattern)) { $pattern.Toggle() }
    else { throw "No supported native action: $id" }
}
try {
    foreach ($scenario in @('sign-success','sign-mixed','sign-fatal','remove-input','change-format','cancel-stamp','history-clear','cancel-pin')) {
        $work = Join-Path $Output $scenario; New-Item -ItemType Directory $work | Out-Null
        $env:MSIGN_TEST_PREFERENCES = Join-Path $work 'settings.json'
        @{Language='en-US';BridgeEnabled=$false;DemoModeEnabled=$true} | ConvertTo-Json | Set-Content $env:MSIGN_TEST_PREFERENCES
        $env:MSIGN_DEMO_CARDS='2'; $env:MSIGN_DEMO_PAGE='sign'; $env:MSIGN_SCREENSHOT_CAPTURE='1'
        $env:MSIGN_UI_TEST_SCENARIO=if ($scenario.StartsWith('sign-')) { $scenario } else { 'sign-success' }
        $env:MSIGN_DEMO_PIN_ONLY=if ($scenario -eq 'cancel-pin') { '1' } else { $null }
        $process = Start-Process $App -PassThru -WorkingDirectory (Split-Path $App)
        try {
            if ($scenario -eq 'cancel-pin') {
                Wait-State 'mock PIN prompt' $process { @(Elements 'SigningPin' $process).Count -eq 1 }
                if (@(Elements 'PinSubmit' $process | Where-Object { $_.Current.IsEnabled }).Count -ne 0) { throw 'Empty PIN accepted' }
                Click 'PinCancel' $process
                if (-not $process.WaitForExit(5000)) { throw 'PIN preview did not close after cancel' }
                $results += @{scenario=$scenario;status='passed';kind='native PIN cancellation without credential entry'}
                continue
            }
            Click 'ChooseDocuments' $process
            Wait-State 'two queued inputs' $process { @(Elements 'SignFileOptions' $process).Count -eq 2 }
            if ($scenario -eq 'remove-input') {
                Click 'SignFileOptions' $process; Click 'RemoveSigningFile' $process
                Wait-State 'one remaining input' $process { @(Elements 'SignFileOptions' $process).Count -eq 1 }
                if (@(Elements 'SignedOutput' $process).Count -ne 0) { throw 'Removal unexpectedly signed' }
            } elseif ($scenario -eq 'cancel-stamp') {
                Click 'SignFileOptions' $process; Click 'EditStamp' $process
                Click 'StampCancel' $process
                Wait-State 'editor dismissed' $process { @(Elements 'StampCancel' $process).Count -eq 0 }
                if (@(Elements 'SignFileOptions' $process).Count -ne 2) { throw 'Cancel changed the queue' }
                if (@(Elements 'SignedOutput' $process).Count -ne 0) { throw 'Cancel unexpectedly signed' }
            } elseif ($scenario -eq 'change-format') {
                Click 'SignFileOptions' $process; Click 'SignFormat1' $process
                Click 'SignFileOptions' $process
                $option = Wait-Element 'SignFormat1' $process
                $toggle = $option.GetCurrentPattern([System.Windows.Automation.TogglePattern]::Pattern)
                Wait-State 'selected format retained' $process { $toggle.Current.ToggleState -eq [System.Windows.Automation.ToggleState]::On }
            } else {
                Click 'SignDocuments' $process
                $expected = @{ 'sign-success'=2; 'sign-mixed'=1; 'sign-fatal'=0; 'history-clear'=2 }[$scenario]
                Wait-State 'completed batch' $process {
                    @(Elements 'SignedOutput' $process).Count -eq $expected -and
                    @(Elements 'SignFileOptions' $process).Count -eq (2-$expected) -and
                    ($expected -eq 2 -or @((Elements 'SignFileError' $process) | Where-Object { $_.Current.Name.Length -gt 0 }).Count -gt 0)
                }
                if (@(Elements 'SigningPin' $process).Count -ne 0) { throw 'Mock signer requested a credential' }
                if ($scenario -eq 'history-clear') {
                    Click 'NavDocuments' $process
                    Wait-State 'saved output library' $process { @(Elements 'SavedDocumentName' $process).Count -ge 2 }
                    $saved = @(Elements 'SavedDocumentName' $process | ForEach-Object { $_.Current.Name } | Sort-Object)
                    $filter = Wait-Element 'DocumentFilter' $process
                    $filter.GetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern).Expand()
                    Click 'HistoryFilter' $process
                    Click 'ClearDocuments' $process; Click 'CloseButton' $process
                    Wait-State 'cancel retains history' $process { @(Elements 'SavedDocumentName' $process).Count -ge 2 }
                    Click 'ClearDocuments' $process; Click 'PrimaryButton' $process
                    Wait-State 'history cleared' $process { @(Elements 'SavedDocumentName' $process).Count -eq 0 }
                    $filter = Wait-Element 'DocumentFilter' $process
                    $filter.GetCurrentPattern([System.Windows.Automation.ExpandCollapsePattern]::Pattern).Expand()
                    Click 'SignedFilter' $process
                    Wait-State 'saved outputs retained' $process { @(Elements 'SavedDocumentName' $process).Count -eq $saved.Count }
                    $after = @(Elements 'SavedDocumentName' $process | ForEach-Object { $_.Current.Name } | Sort-Object)
                    if (Compare-Object $saved $after) { throw 'Clearing history altered saved outputs' }
                }
            }
            $results += @{scenario=$scenario;status='passed';kind='mock service with native controls'}
        } catch { $results += @{scenario=$scenario;status='failed';error=$_.Exception.Message}; throw }
        finally {
            if (-not $process.HasExited) { Stop-Process -Id $process.Id }
            if (-not $process.WaitForExit(10000)) { throw 'Test app did not terminate during cleanup' }
            $process.Dispose()
            ConvertTo-Json -InputObject @($results) -Depth 5 | Set-Content (Join-Path $Output 'results.json')
        }
    }
} finally { foreach ($name in $names) { Set-TestEnvironmentVariable $name $before[$name] } }
