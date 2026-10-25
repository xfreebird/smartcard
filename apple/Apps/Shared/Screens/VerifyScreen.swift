import SwiftUI

/// docs/10 §4.2 "Verifică": drop a signed file → verdict + one card per signature.
struct VerifyScreen: View {
    @Environment(AppModel.self) private var model
    @State private var importing = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                Text("Verifică semnături").font(.title2.weight(.semibold))
                DropZoneView(title: "Trage aici documentul semnat", hint: "PDF semnat sau semnătură XAdES (.xml)",
                             minHeight: model.verifyReports == nil ? 160 : 72,
                             onFiles: { urls in if let url = urls.first { Task { await model.verify(url) } } },
                             onBrowse: { importing = true })
                if let file = model.verifyFile {
                    if let reports = model.verifyReports {
                        VerdictBadge(verdict: Verdict(reports))
                        Text(file.lastPathComponent).font(.subheadline).foregroundStyle(.secondary)
                        ForEach(Array(reports.enumerated()), id: \.offset) { _, report in
                            SignatureCardView(report: report)
                        }
                    } else {
                        ProgressView("Se verifică…")
                    }
                }
            }
            .padding(Theme.Space.xl)
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.pdf, .xml, .item]) { result in
            if case .success(let url) = result { Task { await model.verify(url) } }
        }
    }
}

struct ActivityScreen: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        List {
            if model.activity.isEmpty {
                ContentUnavailableView("Nicio activitate", systemImage: "clock",
                                       description: Text("Documentele semnate și verificate apar aici."))
            }
            ForEach(model.activity) { item in
                ActivityRowView(item: item)
                    .contextMenu {
                        #if os(macOS)
                        if let url = item.fileURL {
                            Button("Arată în Finder") { NSWorkspace.shared.activateFileViewerSelecting([url]) }
                        }
                        #endif
                    }
            }
        }
        .navigationTitle("Activitate")
    }
}

/// docs/10 §4.2 "Card": holder, issuer, validity, PIN storage.
struct CardScreen: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Space.l) {
                HStack(spacing: Theme.Space.l) {
                    CardArt(present: model.status.cardPresent, size: 120)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(model.certificate?.holder ?? model.status.title).font(.title2.weight(.semibold))
                        Text(model.status.subtitle).foregroundStyle(.secondary)
                        HStack {
                            CardPicker().fixedSize()
                            if !model.cards.isEmpty {
                                Button {
                                    model.rereadCards()
                                } label: {
                                    Label("Recitește cardul", systemImage: "arrow.clockwise")
                                }
                                .help(Text("Citește din nou cardurile din cititoare (după ce ai scos sau schimbat un card)"))
                            }
                        }
                    }
                }
                if let cert = model.certificate {
                    CardSurface {
                        VStack(alignment: .leading, spacing: Theme.Space.s) {
                            LabeledContent("Emitent", value: cert.issuerName)
                            if let until = cert.notAfter {
                                LabeledContent("Valabil până la", value: until.formatted(date: .long, time: .omitted))
                            }
                            LabeledContent("Număr de serie", value: cert.serialDecimal)
                            LabeledContent("SHA-1", value: cert.sha1Hex).font(.caption.monospaced())
                        }
                    }
                    CardSurface {
                        VStack(alignment: .leading, spacing: Theme.Space.s) {
                            Label(model.hasStoredPIN ? "PIN-ul este salvat în Keychain" : "PIN-ul nu este salvat",
                                  systemImage: model.hasStoredPIN ? "key.fill" : "key")
                            Text("La semnare, PIN-ul salvat se deblochează cu Touch ID / Face ID sau parola dispozitivului.")
                                .font(.caption).foregroundStyle(.secondary)
                            if model.hasStoredPIN {
                                Button("Șterge PIN-ul salvat", role: .destructive) { model.forgetPIN() }
                            }
                        }
                    }
                }
                CardSurface {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Probleme cu cardul?").font(.headline)
                        Text("• Dacă semnarea eșuează repetat, scoate și reintrodu cardul.")
                        Text("• PIN-ul nu se reîncearcă automat. După 3 încercări greșite cardul se blochează.")
                        Text("• Deblocarea PIN-ului se face la CEV.")
                    }
                    .font(.subheadline)
                }
            }
            .padding(Theme.Space.xl)
        }
    }
}
