import SwiftUI

/// Renders feature progress without knowing the operation or its domain steps.
struct StepProgressView: View {
    let label: String
    let completed: Int
    let total: Int

    var body: some View {
        ProgressView(value: Double(completed), total: Double(total)) {
            Text(label).font(.caption)
        }
        .progressViewStyle(.linear)
        .controlSize(.small)
        .accessibilityLabel(Text(label))
    }
}
