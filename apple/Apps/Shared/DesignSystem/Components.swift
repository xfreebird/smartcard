import SwiftUI
import UniformTypeIdentifiers
import MoldSignKit

// Components from docs/10-design-system.md §3.

/// docs/10 §3 DropZone: dashed area that takes dropped files and has its own "choose" button. Large while the list
/// is empty, one compact line once documents are queued. On iPhone it's simply a big tile (drag works on iPad).
struct DropZone: View {
    var compact = false
    var targeted = false
    let choose: () -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        Group {
            if compact {
                HStack(spacing: Theme.Space.s) {
                    Image(systemName: "arrow.down.doc")
                    Text("Trage alte documente aici sau")
                    Button("Alege fișiere…", action: choose).buttonStyle(.borderless)
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 48)
            } else {
                VStack(spacing: Theme.Space.s) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(targeted ? Color.accentColor : .secondary)
                        .symbolEffect(.bounce, value: targeted)
                    Text(targeted ? "Eliberează pentru a adăuga" : "Trage documentele aici").font(.headline)
                    Text("PDF → PAdES-T în PDF · alte fișiere → XAdES-T separat. Formatul se poate schimba.")
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button("Alege fișiere…", action: choose)
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .padding(.top, Theme.Space.xs)
                }
                .padding(Theme.Space.l)
                .frame(maxWidth: .infinity, minHeight: 190)
            }
        }
        .background(targeted ? Color.accentColor.opacity(0.10) : Color.secondary.opacity(0.05), in: shape)
        .overlay(shape.strokeBorder(targeted ? Color.accentColor : Color.secondary.opacity(0.45),
                                    style: StrokeStyle(lineWidth: targeted ? 2 : 1.5, dash: targeted ? [] : [7, 5])))
        .contentShape(shape)
        .animation(.easeOut(duration: 0.15), value: targeted)
    }
}

/// Card → PIN → Semnătură → Marcă temporală → Salvare.
struct StepProgressView: View {
    let current: SigningService.Step

    private static let steps: [(SigningService.Step, LocalizedStringKey)] = [
        (.authenticating, "Card"), (.verifyingPIN, "PIN"), (.signing, "Semnătură"),
        (.timestamping, "Marcă temporală"), (.writing, "Salvare"),
    ]

    var body: some View {
        HStack(spacing: Theme.Space.s) {
            ForEach(Array(Self.steps.enumerated()), id: \.offset) { index, step in
                let state = stepState(index)
                HStack(spacing: 4) {
                    ZStack {
                        Circle().fill(state == .done ? Theme.success : state == .active ? Theme.brand : .secondary.opacity(0.25))
                            .frame(width: 18, height: 18)
                        if state == .done {
                            Image(systemName: "checkmark").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                        } else if state == .active {
                            ProgressView().controlSize(.mini).tint(.white)
                        }
                    }
                    Text(step.1).font(.caption).foregroundStyle(state == .pending ? .secondary : .primary)
                }
                if index < Self.steps.count - 1 {
                    Rectangle().fill(.secondary.opacity(0.3)).frame(height: 1).frame(maxWidth: 24)
                }
            }
        }
    }

    private enum StepState { case pending, active, done }

    private func stepState(_ index: Int) -> StepState {
        let order: [SigningService.Step] = [.connecting, .authenticating, .readingCertificate, .verifyingPIN,
                                            .signing, .timestamping, .writing, .done]
        let mapped: [SigningService.Step] = [.authenticating, .verifyingPIN, .signing, .timestamping, .writing]
        let cur = order.firstIndex(of: current) ?? 0
        let me = order.firstIndex(of: mapped[index]) ?? 0
        if current == .done || cur > me { return .done }
        return cur == me || (index == 0 && cur < me) ? .active : .pending
    }
}

struct VerdictBadge: View {
    let verdict: Verdict

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            Image(systemName: verdict.symbol)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(verdict.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text(verdict.title).font(.title3.weight(.semibold))
                Text(verdict.subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
        }
    }
}

struct ActivityRowView: View {
    let item: ActivityItem
    /// Off in the menu-bar popover (a glance at what happened, not when).
    var showsDate = true

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            Image(systemName: item.ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(item.ok ? Theme.success : Theme.warning)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title).lineLimit(1).truncationMode(.middle)
                Text(item.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            if showsDate {
                Text(item.date, format: .relative(presentation: .named)).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
