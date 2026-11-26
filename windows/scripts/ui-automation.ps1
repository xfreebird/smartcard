# Query only the tested process's windows, including its separate dialog/popup roots.
# A desktop-wide descendant search can wait on unrelated accessibility providers
# while the app is starting. Keep the caller's conditions, assertions and deadlines.
function Find-AppAutomationElements {
    param(
        [System.Diagnostics.Process]$Process,
        [System.Windows.Automation.Condition]$Condition
    )
    $owner = [System.Windows.Automation.PropertyCondition]::new(
        [System.Windows.Automation.AutomationElement]::ProcessIdProperty, $Process.Id)
    $windows = [System.Windows.Automation.AutomationElement]::RootElement.FindAll(
        [System.Windows.Automation.TreeScope]::Children, $owner)
    foreach ($window in $windows) {
        foreach ($element in $window.FindAll([System.Windows.Automation.TreeScope]::Subtree, $Condition)) {
            $element
        }
    }
}
