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
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Theme.Space.s) {
                        Image(systemName: "arrow.down.doc")
                        Text(L10n.text(.ui_drop_more_documents_here_or)).fixedSize()
                        Button(L10n.text(.ui_choose_files), action: choose).buttonStyle(.borderless).fixedSize()
                    }
                    VStack(spacing: Theme.Space.s) {
                        Label(L10n.text(.ui_drop_more_documents_here_or), systemImage: "arrow.down.doc")
                            .multilineTextAlignment(.center)
                        Button(L10n.text(.ui_choose_files), action: choose).buttonStyle(.borderless)
                    }
                    .padding(.vertical, Theme.Space.s)
                }
                .font(.callout)
                .foregroundStyle(.secondary)
                .padding(.horizontal, Theme.Space.s)
                .frame(maxWidth: .infinity, minHeight: 48)
            } else {
                VStack(spacing: Theme.Space.s) {
                    Image(systemName: "arrow.down.doc")
                        .font(.system(size: 34, weight: .light))
                        .foregroundStyle(targeted ? Color.accentColor : .secondary)
                        .symbolEffect(.bounce, value: targeted)
                    Text(targeted ? L10n.text(.ui_release_to_add) : L10n.text(.ui_drop_documents_here)).font(.headline)
                    Text(L10n.text(.ui_pdf_pades_t_within_the_pdf_other_files_separate_xades_t_the_format_can_be_changed))
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button(L10n.text(.ui_choose_files), action: choose)
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

    private static let steps: [(SigningService.Step, String)] = [
        (.authenticating, L10n.text(.ui_card)), (.verifyingPIN, L10n.text(.ui_pin)), (.signing, L10n.text(.ui_signature)),
        (.timestamping, L10n.text(.ui_timestamp)), (.writing, L10n.text(.ui_saving)),
    ]

    var body: some View {
        let active = Self.steps.indices.first { stepState($0) == .active }
        let completed = Self.steps.indices.filter { stepState($0) == .done }.count
        let label = active.map { Self.steps[$0].1 } ?? (current == .done ? L10n.text(.ui_done) : String(L10n.text(.ui_card)))
        ProgressView(value: Double(completed), total: Double(Self.steps.count)) {
            Text(label).font(.caption)
        }
        .progressViewStyle(.linear)
        .controlSize(.small)
        .accessibilityLabel(Text(label))
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
