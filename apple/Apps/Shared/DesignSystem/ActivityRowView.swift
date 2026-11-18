import SwiftUI

struct ActivityRowView: View {
    let title: String
    let subtitle: String
    let date: Date
    let succeeded: Bool
    /// Off in the menu-bar popover (a glance at what happened, not when).
    var showsDate = true

    var body: some View {
        #if os(iOS)
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.body.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Label {
                Text(subtitle).fixedSize(horizontal: false, vertical: true)
            } icon: {
                Image(systemName: succeeded ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .foregroundStyle(succeeded ? Theme.success : Theme.warning)
            }
            .font(.subheadline).foregroundStyle(.secondary)
            if showsDate {
                Text(date, format: .dateTime.day().month(.abbreviated).year().hour().minute())
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        #else
        HStack(spacing: Theme.Space.m) {
            Image(systemName: succeeded ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(succeeded ? Theme.success : Theme.warning)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .lineLimit(showsDate ? 1 : nil)
                    .truncationMode(.middle)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    .lineLimit(showsDate ? 1 : nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
            if showsDate {
                Text(date, format: .relative(presentation: .named)).font(.caption).foregroundStyle(.secondary)
            }
        }
        #endif
    }
}
