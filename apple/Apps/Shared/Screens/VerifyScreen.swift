import SwiftUI
import UniformTypeIdentifiers
import MoldSignKit

/// "Verifică": choose or drop a signed file → verdict + one section per signature (UX-03/UX-04).
struct VerifyScreen: View {
    @Environment(AppModel.self) private var model
    @State private var importing = false
    @State private var dropTargeted = false

    var body: some View {
        Form {
            Section {
                Button { importing = true } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(model.verifyFile == nil ? "Alege documentul semnat" : "Alege alt document")
                            Text("sau trage-l aici · PDF semnat sau semnătură XAdES (.xml)").font(.caption).foregroundStyle(Color.secondary)
                        }
                    } icon: { Image(systemName: "checkmark.seal") }
                }
                .buttonStyle(.borderless)
            }

            if let file = model.verifyFile {
                if let reports = model.verifyReports {
                    Section {
                        VerdictBadge(verdict: Verdict(reports))
                            .padding(.vertical, 4)
                        LabeledContent("Document", value: file.lastPathComponent)
                    }
                    ForEach(Array(reports.enumerated()), id: \.offset) { index, report in
                        SignatureSection(report: report, index: index + 1)
                    }
                } else {
                    Section { ProgressView("Se verifică…") }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Verifică")
        .overlay {
            if dropTargeted {
                RoundedRectangle(cornerRadius: 12).strokeBorder(Color.accentColor, lineWidth: 2).padding(4).allowsHitTesting(false)
            }
        }
        .dropDestination(for: URL.self) { urls, _ in
            if let url = urls.first { Task { await model.verify(url) } }
            return !urls.isEmpty
        } isTargeted: { dropTargeted = $0 }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.pdf, .xml, .item]) { result in
            if case .success(let url) = result { Task { await model.verify(url) } }
        }
    }
}

private struct SignatureSection: View {
    let report: Validator.Report
    let index: Int

    var body: some View {
        Section {
            LabeledContent("Semnatar", value: report.signer)
            LabeledContent("Semnat la", value: report.signingTime)
            if let tst = report.timestampTime { LabeledContent("Marcă temporală", value: tst) }
            LabeledContent("Nivel", value: report.level)
            check("Integritatea documentului", report.contentIntact)
            check("Semnătura criptografică", report.signatureValid)
            check("Lanț de încredere (MDQSign → mdtrustca)", report.chainTrusted)
            DisclosureGroup("Detalii tehnice") {
                Text(report.summary).font(.caption.monospaced()).textSelection(.enabled)
            }
        } header: {
            Text("Semnătura \(index)")
        }
    }

    private func check(_ title: LocalizedStringKey, _ ok: Bool) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: ok ? "checkmark.circle.fill" : "xmark.octagon.fill")
                .foregroundStyle(ok ? .green : .red)
        }
    }
}

struct ActivityScreen: View {
    @Environment(AppModel.self) private var model
    @State private var confirmClear = false

    var body: some View {
        List {
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
        .overlay {
            if model.activity.isEmpty {
                ContentUnavailableView("Nicio activitate", systemImage: "clock",
                                       description: Text("Documentele semnate și verificate apar aici."))
            }
        }
        .navigationTitle("Activitate")
        .onAppear { model.pruneMissingFiles() }      // moved/deleted documents drop out of the list
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(role: .destructive) { confirmClear = true } label: { Label("Golește lista", systemImage: "trash") }
                    .disabled(model.activity.isEmpty)
                    .help("Șterge istoricul (documentele rămân pe disc)")
            }
        }
        .confirmationDialog("Golești lista de activitate?", isPresented: $confirmClear, titleVisibility: .visible) {
            Button("Golește lista", role: .destructive) { model.clearActivity() }
        } message: {
            Text("Documentele semnate rămân pe disc; se șterge doar istoricul.")
        }
    }
}

/// "Card": the card selector + the selected card's certificate and PIN.
struct CardScreen: View {
    @Environment(AppModel.self) private var model
    @State private var copied = false

    var body: some View {
        Form {
            Section {
                CardSelector(size: cardSize)
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
            } footer: {
                if model.cards.count > 1 {
                    #if os(macOS)
                    Text("Schimbă cardul din colțul lui (1/2), cu ←/→ sau glisând pe trackpad. Clic dreapta pentru a-l reciti.")
                    #else
                    Text("Glisează cardul sau atinge 1/2 din colțul lui pentru a schimba cardul. Ține apăsat pentru a-l reciti.")
                    #endif
                }
            }

            if let cert = model.certificate {
                Section("Certificat de semnătură") {
                    LabeledContent("Titular", value: cert.holder)
                    LabeledContent("Emitent", value: cert.issuerName)
                    if let until = cert.notAfter {
                        LabeledContent("Valabil până la", value: until.formatted(date: .long, time: .omitted))
                    }
                    LabeledContent("Număr de serie", value: cert.serialDecimal)
                    LabeledContent("SHA-1") {
                        HStack {
                            Text(cert.sha1Hex).font(.caption.monospaced()).textSelection(.enabled)
                            Button {
                                copy(cert.sha1Hex)
                            } label: { Image(systemName: copied ? "checkmark" : "doc.on.doc") }
                                .buttonStyle(.borderless)
                                .accessibilityLabel("Copiază SHA-1")
                        }
                    }
                    if let reader = model.selectedCard?.reader { LabeledContent("Cititor", value: reader) }
                }
                Section {
                    Label(model.hasStoredPIN ? "PIN-ul este salvat" : "PIN-ul nu este salvat",
                          systemImage: model.hasStoredPIN ? "key.fill" : "key")
                    if model.hasStoredPIN {
                        Button("Șterge PIN-ul salvat", role: .destructive) { model.forgetPIN() }
                    }
                } header: {
                    Text("PIN")
                } footer: {
                    Text("PIN-ul salvat se deblochează cu Touch ID / Face ID sau parola dispozitivului și este legat de acest card.")
                }
            }

            Section("Probleme cu cardul?") {
                Label("Dacă semnarea eșuează repetat, scoate și reintrodu cardul.", systemImage: "arrow.triangle.2.circlepath")
                Label("PIN-ul nu se reîncearcă automat. După 3 încercări greșite cardul se blochează.", systemImage: "lock.shield")
                Label("Deblocarea PIN-ului se face la CEV.", systemImage: "building.columns")
            }
            .font(.callout)
        }
        .formStyle(.grouped)
        .navigationTitle("Card")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { model.rereadCards() } label: { Label("Recitește cardul", systemImage: "arrow.clockwise") }
                    .disabled(model.cards.isEmpty)
                    .help("Citește din nou cardurile (după ce ai scos sau schimbat un card)")
            }
        }
    }

    private var cardSize: CardSelector.Size {
        #if os(macOS)
        return .large
        #else
        return .phone
        #endif
    }

    private func copy(_ text: String) {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #else
        UIPasteboard.general.string = text
        #endif
        copied = true
    }
}
