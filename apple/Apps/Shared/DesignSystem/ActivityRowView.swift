import SwiftUI

struct ActivityRowView: View {
    let title: String
    let subtitle: String
    let date: Date
    let succeeded: Bool
    /// Off in the menu-bar popover (a glance at what happened, not when).
    var showsDate = true

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            Image(systemName: succeeded ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(succeeded ? Theme.success : Theme.warning)
            VStack(alignment: .leading, spacing: 1) {
                Text(title).lineLimit(1).truncationMode(.middle)
                Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            if showsDate {
                Text(date, format: .relative(presentation: .named)).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
