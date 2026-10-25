import SwiftUI

/// docs/10 §4.1: status card, drop-to-sign zone, recent activity, browser bridge toggle.
struct MenuBarPopover: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: Theme.Space.m) {
            HStack {
                Text("MoldSign").font(.headline)
                Spacer()
                Button { openSettings() } label: { Image(systemName: "gearshape") }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("Setări")
            }

            StatusCardView(status: model.status)
            CardPicker()

            if let step = model.currentStep {
                StepProgressView(current: step)
            } else {
                DropZoneView(minHeight: 96,
                             onFiles: { urls in
                                 model.addFiles(urls)
                                 Task { await model.signAll() }
                             },
                             onBrowse: { showMain() })
                    .disabled(!model.status.canSign)
            }
            if let error = model.lastError {
                Label("\(error.message). \(error.recovery)", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(Theme.danger)
            }

            HStack {
                Button("Semnează…") { showMain() }
                Spacer()
                Button("Verifică…") { showMain() }
            }
            .controlSize(.large)

            if !model.activity.isEmpty {
                Text("RECENTE").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                ForEach(model.activity.prefix(4)) { item in
                    ActivityRowView(item: item).font(.subheadline)
                }
            }

            Divider()
            Toggle(isOn: $model.bridgeEnabled) {
                Label(bridgeText, systemImage: "globe")
            }
            .toggleStyle(.switch)
            .controlSize(.small)

            HStack {
                Button("Deschide fereastra") { showMain() }
                Spacer()
                Button("Ieșire") { NSApp.terminate(nil) }
            }
            .buttonStyle(.borderless)
        }
        .padding(Theme.Space.l)
        .frame(width: Theme.popoverWidth)
    }

    private var bridgeText: String {
        switch model.bridgeState {
        case .running: return String(localized: "Conexiune browser activă")
        case .stopped: return String(localized: "Conexiune browser oprită")
        case .portBusy: return String(localized: "Porturile sunt ocupate de MoldSign (Java)")
        case .failed: return String(localized: "Conexiune browser: eroare")
        }
    }

    private func showMain() {
        openWindow(id: "main")
        NSApp.activate()
    }
}

/// Sidebar: Semnează · Verifică · Activitate · Card (docs/10 §4.2).
struct MainWindowView: View {
    enum Section: String, CaseIterable, Identifiable {
        case sign, verify, activity, card
        var id: String { rawValue }
        var title: LocalizedStringKey {
            switch self {
            case .sign: return "Semnează"
            case .verify: return "Verifică"
            case .activity: return "Activitate"
            case .card: return "Card"
            }
        }
        var symbol: String {
            switch self {
            case .sign: return "signature"
            case .verify: return "checkmark.seal"
            case .activity: return "clock"
            case .card: return "person.text.rectangle"
            }
        }
    }

    @State private var section: Section? = .sign

    var body: some View {
        NavigationSplitView {
            List(Section.allCases, selection: $section) { item in
                Label(item.title, systemImage: item.symbol).tag(item)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            switch section ?? .sign {
            case .sign: SignScreen()
            case .verify: VerifyScreen()
            case .activity: ActivityScreen()
            case .card: CardScreen()
            }
        }
    }
}
