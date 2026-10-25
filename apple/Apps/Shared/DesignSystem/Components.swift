import SwiftUI
import UniformTypeIdentifiers
import MoldSignKit

// Components from docs/10-design-system.md §3.

/// Stylized eID card: blue card with the yellow chip. Outline-only when no card is present.
struct CardArt: View {
    var present: Bool
    var size: CGFloat = 44

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
            .fill(present ? AnyShapeStyle(Theme.brand.gradient) : AnyShapeStyle(.clear))
            .overlay(RoundedRectangle(cornerRadius: size * 0.12, style: .continuous)
                .strokeBorder(present ? .clear : .secondary, style: StrokeStyle(lineWidth: 1.5, dash: [4, 3])))
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: size * 0.05)
                    .fill(present ? Theme.accent : .secondary.opacity(0.4))
                    .frame(width: size * 0.22, height: size * 0.17)
                    .padding(.leading, size * 0.14)
            }
            .frame(width: size, height: size * 0.63)
            .accessibilityHidden(true)
    }
}

/// "Can I sign right now?" Holder, reader and validity, or the one thing to fix.
struct StatusCardView: View {
    let status: ReaderStatus
    var compact = false

    var body: some View {
        CardSurface(padding: compact ? Theme.Space.m : Theme.Space.l) {
            HStack(spacing: Theme.Space.m) {
                CardArt(present: status.cardPresent, size: compact ? 36 : 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.title)
                        .font(compact ? .subheadline.weight(.semibold) : .headline)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Circle().fill(status.tint).frame(width: 7, height: 7)
                        Text(status.subtitle).lineLimit(1)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    if !compact, let detail = status.detail {
                        Text(detail).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                if case .reading = status { ProgressView().controlSize(.small) }
                if case .busy = status { ProgressView().controlSize(.small) }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

/// Dashed drop target. Dropping files starts the flow; tapping opens the file picker.
struct DropZoneView: View {
    var title: LocalizedStringKey = "Trage documentele aici"
    var subtitle: LocalizedStringKey = "sau alege fișiere"
    var hint: LocalizedStringKey? = "PDF → PAdES · altele → XAdES"
    var minHeight: CGFloat = 120
    let onFiles: ([URL]) -> Void
    let onBrowse: () -> Void

    @State private var targeted = false

    var body: some View {
        Button(action: onBrowse) {
            VStack(spacing: Theme.Space.s) {
                Image(systemName: "arrow.down.doc")
                    .font(.system(size: 26, weight: .regular))
                    .foregroundStyle(targeted ? Theme.brand : .secondary)
                Text(title).font(.headline)
                Text(subtitle).font(.subheadline).foregroundStyle(Theme.brand)
                if let hint { Text(hint).font(.caption).foregroundStyle(.secondary) }
            }
            .frame(maxWidth: .infinity, minHeight: minHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(targeted ? Theme.brandSoft : .clear,
                    in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
            .strokeBorder(targeted ? Theme.brand : .secondary.opacity(0.5),
                          style: StrokeStyle(lineWidth: 1.5, dash: targeted ? [] : [6, 4])))
        .dropDestination(for: URL.self) { urls, _ in
            onFiles(urls)
            return !urls.isEmpty
        } isTargeted: { targeted = $0 }
        .animation(.easeOut(duration: 0.2), value: targeted)
    }
}

/// Which inserted card to sign with, shown only when several eID cards are connected.
struct CardPicker: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        if model.cards.count > 1 {
            Picker(selection: Binding(get: { model.selectedCard?.reader ?? "" }, set: { model.selectCard($0) })) {
                ForEach(model.cards) { card in
                    Text(card.certificate?.holder ?? String(localized: "Se citește…")).tag(card.reader)
                }
            } label: {
                Label("Card", systemImage: "person.text.rectangle")
            }
            .pickerStyle(.menu)
            .accessibilityHint(Text("Alege cardul cu care semnezi"))
        }
    }
}

struct FormatChip: View {
    let format: SignFormat

    var body: some View {
        Text(format.label)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(Theme.brand)
            .background(Theme.brandSoft, in: Capsule())
    }
}

struct FileRowView: View {
    let item: SignItem
    var onRemove: (() -> Void)?

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            Image(systemName: item.format == .padesT ? "doc.richtext" : "doc")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.url.lastPathComponent).lineLimit(1).truncationMode(.middle)
                Text(item.sizeText).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            FormatChip(format: item.format)
            if let onRemove {
                Button(action: onRemove) { Image(systemName: "xmark.circle.fill") }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                    .accessibilityLabel("Elimină")
            }
        }
        .padding(.vertical, 4)
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

struct SignatureCardView: View {
    let report: Validator.Report
    @State private var showDetails = false

    var body: some View {
        CardSurface {
            VStack(alignment: .leading, spacing: Theme.Space.s) {
                HStack {
                    Image(systemName: "person.text.rectangle").foregroundStyle(Theme.brand)
                    Text(report.signer).font(.headline)
                    Spacer()
                    Text(report.level).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                }
                Text("Semnat \(report.signingTime)").font(.subheadline)
                if let tst = report.timestampTime {
                    Text("Marcă temporală \(tst)").font(.caption).foregroundStyle(.secondary)
                }
                HStack(spacing: Theme.Space.s) {
                    check("Integritate", report.contentIntact)
                    check("Semnătură", report.signatureValid)
                    check("Lanț de încredere", report.chainTrusted)
                }
                DisclosureGroup("Detalii tehnice", isExpanded: $showDetails) {
                    Text(report.summary).font(.caption.monospaced()).textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .font(.caption)
            }
        }
    }

    private func check(_ title: LocalizedStringKey, _ ok: Bool) -> some View {
        Label(title, systemImage: ok ? "checkmark.circle.fill" : "xmark.octagon.fill")
            .font(.caption)
            .foregroundStyle(ok ? Theme.success : Theme.danger)
    }
}

struct ActivityRowView: View {
    let item: ActivityItem

    var body: some View {
        HStack(spacing: Theme.Space.m) {
            Image(systemName: item.ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(item.ok ? Theme.success : Theme.warning)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title).lineLimit(1).truncationMode(.middle)
                Text(item.subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer()
            Text(item.date, style: .relative).font(.caption).foregroundStyle(.secondary)
        }
    }
}
