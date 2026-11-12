import SwiftUI

/// docs/10 §3 DropZone: a clear, solid file action with its own "choose" button. Large while the list
/// is empty, one compact line once documents are queued. On iPhone it's simply a big tile (drag works on iPad).
struct DropZone: View {
    let labels: DropZoneLabels
    var verification = false
    var compact = false
    var short = false
    var targeted = false
    let choose: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        Group {
            if short {
                Button(action: choose) {
                    Label(labels.choose, systemImage: verification ? "checkmark.seal" : "arrow.down.doc")
                        .frame(maxWidth: .infinity, minHeight: 44)
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, Theme.Space.s)
            } else if compact {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Space.s) {
                        Image(systemName: "arrow.down.doc")
                        Text(labels.addMore).fixedSize()
                        Button(labels.choose, action: choose).buttonStyle(.bordered).fixedSize()
                    }
                    VStack(spacing: Theme.Space.s) {
                        Label(labels.addMore, systemImage: "arrow.down.doc")
                            .multilineTextAlignment(.center)
                        Button(labels.choose, action: choose).buttonStyle(.bordered)
                    }
                    .padding(.vertical, Theme.Space.s)
                }
                .font(.callout)
                .foregroundStyle(.primary)
                .padding(.horizontal, Theme.Space.s)
                .frame(maxWidth: .infinity, minHeight: 48)
            } else {
                VStack(spacing: Theme.Space.s) {
                    Image(systemName: verification ? "checkmark.seal" : "arrow.down.doc")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(targeted ? Color.accentColor : .secondary)
                        .symbolEffect(.bounce, value: targeted)
                    Text(targeted ? labels.release : labels.drop).font(.headline)
                    Text(labels.hint)
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button(labels.choose, action: choose)
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .padding(.top, Theme.Space.xs)
                }
                .padding(Theme.Space.l)
                .frame(maxWidth: .infinity, minHeight: 190)
            }
        }
        .background(targeted ? Color.accentColor.opacity(0.12) : (compact ? Color.accentColor.opacity(0.07) : Color.secondary.opacity(0.05)), in: shape)
        // `ViewThatFits` may choose a child wider than its proposal (notably when a
        // long localized filename is queued).  Clip the fill as well as the child so
        // the compact add-document action always retains its continuous corners.
        .clipShape(shape)
        .overlay(shape.strokeBorder(targeted ? Color.accentColor : Color.secondary.opacity(0.58),
                                    style: StrokeStyle(lineWidth: targeted ? 2 : 1, dash: [6, 4])))
        .contentShape(shape)
        .animation(.easeOut(duration: 0.15), value: targeted)
    }
}
