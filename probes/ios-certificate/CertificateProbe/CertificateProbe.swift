import SwiftUI
import CryptoTokenKit
import MoldSignKit

@main struct CertificateProbeApp: App {
    init() { MSLog.sink = nil }
    var body: some Scene { WindowGroup { ProbeScreen() } }
}

private struct ProbeScreen: View {
    @State private var readers: [String] = []
    @State private var selected = ""
    @State private var report = "Connect the reader and insert the card. No PIN is needed."
    @State private var busy = false
    @State private var folder: URL?
    @State private var certificates: [URL] = []
    @State private var confirmSecure = false
    @State private var controlsRequested = false
    @State private var outcome = ""
    @State private var showingPIN = false
    @State private var pin = ""
    @State private var fileProbeRequested = false

    var body: some View {
        NavigationStack {
            List {
                Section("Reader") {
                    Button("Refresh readers", action: refresh).disabled(busy)
                    if readers.isEmpty { Text("No reader with a responsive card") }
                    else {
                        Picker("Reader", selection: $selected) {
                            ForEach(readers, id: \.self) { Text($0).tag($0) }
                        }
                    }
                }
                Section("Public certificate checks") {
                    Button("1. Read public files (no authentication)") { run(secure: false) }
                        .disabled(busy || selected.isEmpty)
                    Button("2. Check app encryption discovery") { controlsRequested = false; confirmSecure = true }
                        .disabled(busy || selected.isEmpty)
                    Button("3. Read key access conditions (no PIN)") { controlsRequested = true; confirmSecure = true }
                        .disabled(busy || selected.isEmpty)
                    Button("4. One RSA decryption test (PIN required)") { fileProbeRequested = false; showingPIN = true }
                        .disabled(busy || selected.isEmpty || DecipherProbeLock.exists)
                    Button("5. One file-sharing test (PIN required)") { fileProbeRequested = true; showingPIN = true }
                        .disabled(busy || selected.isEmpty || !DecipherProbeLock.exists || DecipherProbeLock.fileRoundTripExists)
                    if DecipherProbeLock.exists { Text("The one-attempt decryption lock is set. Do not uninstall or reset this app to repeat the test.").font(.footnote) }
                    Text("Checks 1–3 read public metadata without a PIN or private-key operation. Check 4 alone permits one owner-started PIN verification and one synthetic decryption. No signing or card writes. Stop after a security-state error.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if busy { ProgressView("Reading card…") }
                Section("Result") {
                    if !outcome.isEmpty { Text(outcome).font(.callout.bold()).textSelection(.enabled) }
                    DisclosureGroup("Detailed report") {
                        Text(report).font(.system(.caption, design: .monospaced)).textSelection(.enabled)
                    }
                }
                if !certificates.isEmpty {
                    Section("Export public certificates") {
                        Text("A certificate can contain your name and identity number. Only an encryption-capable certificate can be used for this file-sharing workflow.").font(.footnote)
                        ForEach(certificates, id: \.self) { url in ShareLink(item: url) { Text(url.lastPathComponent) } }
                    }
                }
                if let folder { Section { Text("Private evidence: Files → On My iPhone → Certificate Probe → \(folder.lastPathComponent)").font(.footnote) } }
            }
            .navigationTitle("Certificate Probe")
            .onAppear(perform: refresh)
            .sheet(isPresented: $showingPIN, onDismiss: { pin = "" }) {
                NavigationStack {
                    Form {
                        Section("Diagnostic only") {
                            Text(fileProbeRequested
                                 ? "Decrypt a synthetic file encrypted independently with OpenSSL using the exported public certificate. Also create a file through the app’s Card public key compatibility path. Compare the restored bytes with the synthetic original. No document is signed."
                                 : "Encrypt one random 16-byte value with this card’s public RSA key, then ask the card to decrypt it. No document is signed and no real file is used. This does not change the certificate’s declared usage.")
                            Text("One PIN verification only. A wrong PIN reduces remaining attempts. The test stays locked after verification, including after restart or update. Do not uninstall the probe to bypass its lock.")
                        }
                        Section("Enter the existing card PIN on this phone") {
                            SecureField("Card PIN", text: $pin).keyboardType(.numberPad)
                                .textContentType(.none).autocorrectionDisabled()
                            Text("Do not send your PIN in chat. The PIN is not saved or written to reports.").font(.footnote)
                        }
                        Button("Run the one decryption test") {
                            let provided = pin
                            pin = ""
                            showingPIN = false
                            run(secure: true, diagnosticPIN: provided, fileProbe: fileProbeRequested)
                        }.disabled(!(6...8).contains(pin.utf8.count) || !pin.utf8.allSatisfy { (48...57).contains($0) } || (fileProbeRequested ? DecipherProbeLock.fileRoundTripExists : DecipherProbeLock.exists))
                    }
                    .navigationTitle("RSA capability test")
                    .onAppear {
                        // Present only in the owner's ignored, device-only probe build.
                        if let supplied = Bundle.main.object(forInfoDictionaryKey: "ProbeDiagnosticPIN") as? String {
                            pin = supplied
                        }
                    }
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { pin = ""; showingPIN = false } } }
                }
            }
            .confirmationDialog("Check the existing app path?", isPresented: $confirmSecure, titleVisibility: .visible) {
                Button("Read metadata through secure channel") { run(secure: true, controls: controlsRequested) }
            } message: { Text("No PIN will be requested or sent. One connection only; no automatic retry.") }
        }
    }

    private func refresh() {
        readers = CardTransports.readersWithCards()
        if !readers.contains(selected) { selected = readers.first ?? "" }
        if !busy, folder == nil {
            let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let candidates = (try? FileManager.default.contentsOfDirectory(at: documents,
                includingPropertiesForKeys: [.contentModificationDateKey])) ?? []
            let reports = candidates.filter { $0.lastPathComponent.hasPrefix("certificate-") }.sorted {
                ((try? $0.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast) >
                ((try? $1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast)
            }
            if let latest = reports.first, let data = try? Data(contentsOf: latest.appendingPathComponent("report.txt")),
               data.count <= 262144, let text = String(data: data, encoding: .utf8) {
                report = text
                outcome = text.components(separatedBy: "\n").last ?? ""
                folder = latest
                certificates = ((try? FileManager.default.contentsOfDirectory(at: latest, includingPropertiesForKeys: nil)) ?? []).filter { $0.pathExtension == "cer" }
            }
        }
    }

    private func run(secure: Bool, controls: Bool = false, diagnosticPIN: String? = nil, fileProbe: Bool = false) {
        guard !busy, !selected.isEmpty else { return }
        busy = true
        report = "Starting…"
        outcome = "Reading…"
        certificates = []
        let reader = selected
        Task {
            let result = await Task.detached { () -> (String, URL?, [URL]) in
                let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "unknown"
                var lines = ["Certificate Probe build \(build)", "Date: \(ISO8601DateFormatter().string(from: Date()))", "Mode: \(fileProbe ? "single file-sharing round trip" : diagnosticPIN != nil ? "single synthetic RSA decipher" : controls ? "public control parameters" : secure ? "production discovery" : "public files")"]
                var directory: URL?, exports: [URL] = []
                do {
                    let documents = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                    let target = documents.appendingPathComponent("certificate-\(UUID().uuidString)", isDirectory: true)
                    try FileManager.default.createDirectory(at: target, withIntermediateDirectories: false, attributes: [.protectionKey: FileProtectionType.complete])
                    directory = target
                    if secure {
                        let service = SigningService()
                        service.transportFactory = {
                            ReadOnlyProbeTransport(try CardTransports.connect(reader: $0), log: { lines.append($0) }, allowDecipher: diagnosticPIN != nil,
                                                   beforeVerify: {
                                if fileProbe {
                                    try DecipherProbeLock.createFileRoundTrip()
                                    lines.append("File-test lock created before PIN verification; original RSA lock preserved")
                                }
                            })
                        }
                        let found: [CardEncryptionIdentity] = try service.withCard(reader: reader, progress: { lines.append("Stage: \($0.rawValue)") }) {
                            if let diagnosticPIN {
                                if fileProbe {
                                    let incoming = documents.appendingPathComponent("file-sharing-input", isDirectory: true)
                                    let expected = try ProtectedFileIO.read(incoming.appendingPathComponent("original.bin"))
                                    let envelope = try ProtectedFileIO.read(incoming.appendingPathComponent("sender.asymmetric.p7m"))
                                    let certificate = try ProtectedFileIO.read(incoming.appendingPathComponent("recipient.cer"))
                                    let identities = try $0.encryptionIdentities(policy: .cardPublicKey)
                                    guard identities.count == 1, let identity = identities.first,
                                          identity.certificate == certificate else { throw CardError.cardChanged }
                                    let exported = target.appendingPathComponent("public-certificate.cer")
                                    try certificate.write(to: exported, options: [.atomic,.completeFileProtection])
                                    exports.append(exported)
                                    let native = try CertificateFileProtection.encrypt(expected,certificate: certificate,policy: .cardPublicKey)
                                    try native.write(to: target.appendingPathComponent("native-sender.asymmetric.p7m"),options: [.atomic,.completeFileProtection])
                                    lines.append("Native CMS encryption: \(native.count) bytes; exported DER matches the selected card")
                                    let restored = try $0.decryptFile(envelope,identity: identity,pin: diagnosticPIN)
                                    guard restored == expected else { throw ProbeFailure.message("Restored file bytes differ") }
                                    try restored.write(to: target.appendingPathComponent("restored.bin"),options: [.atomic,.completeFileProtection])
                                    lines.append("OpenSSL sender file decrypted through production card workflow: \(restored.count) exact bytes")
                                    return []
                                }
                                lines.append("Stage: independently bound synthetic RSA challenge")
                                let passed = try $0.probeDecipherCapability(pin: diagnosticPIN) {
                                    try DecipherProbeLock.create()
                                    lines.append("One-attempt lock created before PIN verification")
                                }
                                guard passed else { throw ProbeFailure.message("Card plaintext did not match the synthetic challenge") }
                                lines.append("RSA challenge: exact 16-byte match")
                                return []
                            }
                            if controls {
                                lines.append("Stage: RSA key / PIN public control parameters")
                                try $0.inspectDecipherControlParameters { name, data in
                                    try data.write(to: target.appendingPathComponent(name + ".bin"), options: [.atomic, .completeFileProtection])
                                    lines.append("\(name): \(data.count) public metadata bytes saved privately")
                                }
                                return []
                            }
                            lines.append("Stage: normal signing-certificate read (control)")
                            let certificate = try $0.readCertificate()
                            let certificateURL = target.appendingPathComponent("signing-certificate.cer")
                            try certificate.write(to: certificateURL, options: [.atomic, .completeFileProtection])
                            exports.append(certificateURL)
                            let usable = (try? CertificateFileProtection.validateRecipient(certificate)) != nil
                            lines.append("Control certificate: \(certificate.count) bytes; RSA recipient validation \(usable ? "accepted" : "rejected")")
                            for file: UInt16 in [0x7001, 0x7002, 0x7005] {
                                let name = String(format: "EF-%04X", file)
                                lines.append("Stage: protected \(name)")
                                let data = try $0.inspectPublicEncryptionFile(file)
                                try data.write(to: target.appendingPathComponent(name + ".bin"), options: [.atomic, .completeFileProtection])
                                lines.append("\(name): \(data.count) bytes saved privately")
                            }
                            lines.append("Stage: PKCS#15 encryption identities")
                            return try $0.encryptionIdentities()
                        }
                        if !controls && diagnosticPIN == nil { lines.append("Usable encryption identities: \(found.count)") }
                        for (index, identity) in found.enumerated() {
                            let url = target.appendingPathComponent("encryption-\(index+1).cer")
                            try identity.certificate.write(to: url, options: [.atomic, .completeFileProtection])
                            exports.append(url)
                        }
                    } else {
                        let transport = ReadOnlyProbeTransport(try CardTransports.connect(reader: reader))
                        defer { transport.disconnect() }
                        try PublicCardReader(transport: transport, log: { lines.append($0) }, save: { name, bytes in
                            let url = target.appendingPathComponent(name)
                            try bytes.write(to: url, options: [.atomic, .completeFileProtection])
                            if url.pathExtension == "cer" { exports.append(url) }
                        }).run()
                    }
                    lines.append(diagnosticPIN == nil ? "Completed; no PIN/private-key commands sent." : fileProbe ? "PASSED: OpenSSL-encrypted file restored byte for byte with the card. One PIN verification; no signature." : "PASSED: one PIN verification and one RSA decipher; exact plaintext match. No signature created.")
                } catch { lines.append("Stopped: \(error.localizedDescription)") }
                var text = lines.joined(separator: "\n")
                if let directory {
                    do { try Data(text.utf8).write(to: directory.appendingPathComponent("report.txt"), options: [.atomic, .completeFileProtection]) }
                    catch { text += "\nReport save failed: \(error.localizedDescription)" }
                }
                return (text, directory, exports)
            }.value
            report = result.0
            outcome = result.0.components(separatedBy: "\n").last ?? "No result"
            folder = result.1
            certificates = result.2
            busy = false
        }
    }
}
