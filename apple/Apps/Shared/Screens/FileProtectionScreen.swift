import SwiftUI
import UniformTypeIdentifiers
import MoldSignKit

struct FileProtectionScreen: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @State private var operation = 0
    @State private var method = 0
    @State private var input: URL?
    @State private var certificate: Data?
    @State private var certificateName = ""
    @State private var identities: [CardEncryptionIdentity] = []
    @State private var identity: CardEncryptionIdentity?
    @State private var identityReader: String?
    @State private var password = ""
    @State private var confirmation = ""
    @State private var pin = ""
    @State private var importing = false
    @State private var importingCertificate = false
    @State private var exporting = false
    @State private var exportingCertificate = false
    @State private var certificateExport: ProtectedExport?
    @State private var certificateExportName = "encryption-certificate.cer"
    @State private var confirmRemoval = false
    @State private var busy = false
    @State private var result: ProtectedExport?
    @State private var notice: L10n.Key?
    @State private var isError = false

    private var ready: Bool {
        guard input != nil, !busy else { return false }
        if operation == 2 { return true }
        if method == 0 { return !password.isEmpty && (operation == 1 || password == confirmation) }
        return operation == 0 ? certificate != nil : identity != nil && !pin.isEmpty
    }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(L10n.text(.protect_operation), selection: $operation) {
                        Text(L10n.text(.protect_encrypt)).tag(0)
                        Text(L10n.text(.protect_decrypt)).tag(1)
                        #if os(macOS)
                        Text(L10n.text(.protect_remove)).tag(2)
                        #endif
                    }.pickerStyle(.segmented)
                }
                Section(L10n.text(.protect_file_step)) {
                    Button { importingCertificate = false; importing = true } label: {
                        Label(input?.lastPathComponent ?? L10n.text(.protect_choose_file), systemImage: "doc.badge.plus")
                            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                            .contentShape(Rectangle())
                    }.buttonStyle(.bordered).accessibilityIdentifier("protect.chooseFile")
                }
                if operation != 2 {
                    Section(L10n.text(.protect_access_step)) {
                        Picker(L10n.text(.protect_method), selection: $method) {
                            Text(L10n.text(.protect_password)).tag(0)
                            Text(L10n.text(.protect_certificate)).tag(1)
                        }.pickerStyle(.segmented)
                        Text(L10n.text(requirementsKey)).font(.callout).foregroundStyle(.secondary)
                        if method == 0 {
                            VStack(alignment: .leading, spacing: 12) {
                                SecureField(L10n.text(.protect_password), text: $password, prompt: Text(L10n.text(.protect_password)).foregroundColor(.secondary)).textContentType(.password)
                                if operation == 0 {
                                    SecureField(L10n.text(.protect_confirm_password), text: $confirmation, prompt: Text(L10n.text(.protect_confirm_password)).foregroundColor(.secondary)).textContentType(.password)
                                    if !confirmation.isEmpty && password != confirmation {
                                        Text(L10n.text(.protect_mismatch)).font(.caption).foregroundStyle(.red)
                                    }
                                }
                            }
                            #if os(macOS)
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                            #endif
                        } else {
                            VStack(alignment: .leading, spacing: 12) {
                                if operation == 0 {
                                    Button { importingCertificate = true; importing = true } label: {
                                        Label(L10n.text(.protect_choose_certificate), systemImage: "person.text.rectangle")
                                    }.buttonStyle(.bordered)
                                }
                                Button(action: readCard) {
                                    Label(L10n.text(.protect_read_card), systemImage: "creditcard")
                                }.buttonStyle(.bordered).disabled(model.selectedCard == nil || model.demoMode)
                                if identities.count > 1 {
                                    Picker(L10n.text(.protect_recipient), selection: Binding(get: { identity?.fingerprint ?? "" }, set: { fingerprint in
                                        identity = identities.first { $0.fingerprint == fingerprint }
                                        certificate = identity?.certificate; certificateName = identity?.label ?? ""; pin = ""; clearResult()
                                    })) {
                                        ForEach(identities, id: \.fingerprint) { item in
                                            Text(item.label + " · " + item.fingerprint.suffix(8)).tag(item.fingerprint)
                                        }
                                    }
                                }
                                if !certificateName.isEmpty {
                                    Text(certificateName).font(.callout.weight(.medium)).textSelection(.enabled)
                                }
                                if let identity {
                                    DisclosureGroup(L10n.text(.protect_details)) {
                                        Text(identity.fingerprint).font(.caption.monospaced()).foregroundStyle(.secondary)
                                            .textSelection(.enabled)
                                        Button {
                                            certificateExport = ProtectedExport(data: identity.certificate)
                                            certificateExportName = "encryption-\(identity.fingerprint).cer"
                                            exportingCertificate = true
                                        } label: { Label(L10n.text(.protect_export_certificate), systemImage: "square.and.arrow.up") }
                                        Text(L10n.text(.protect_export_certificate_hint)).font(.caption).foregroundStyle(.secondary)
                                    }
                                    if operation == 1 { SecureField(L10n.text(.protect_card_pin),text: $pin, prompt: Text(L10n.text(.protect_card_pin)).foregroundColor(.secondary)).textFieldStyle(.roundedBorder) }
                                }
                            }
                        }
                        DisclosureGroup(L10n.text(.protect_help)) {
                            Text(L10n.text(helpKey)).font(.callout)
                            Text(L10n.text(.protect_compatibility)).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .safeAreaInset(edge: .bottom) {
                VStack(alignment: .leading, spacing: 12) {
                    if operation == 2 {
                        Label(L10n.text(.protect_removal_warning),systemImage:"exclamationmark.triangle")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                    if operation != 2 { Text(L10n.text(.protect_original)).font(.caption).foregroundStyle(.secondary) }
                    if busy { ProgressView(L10n.text(.protect_working)) }
                    if let notice {
                        Label(L10n.text(notice), systemImage: isError ? "exclamationmark.circle" : "checkmark.circle")
                            .foregroundStyle(isError ? Color.red : Color.primary)
                            .accessibilityIdentifier("protect.result")
                    }
                    if result != nil {
                        Button { exporting = true } label: {
                            Label(L10n.text(.protect_save), systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity, minHeight: 40)
                        }.buttonStyle(.borderedProminent)
                    } else {
                        Button {
                            if operation == 2 { confirmRemoval = true } else { process() }
                        } label: {
                            Text(L10n.text(operation == 0 ? .protect_encrypt : operation == 1 ? .protect_decrypt : .protect_remove))
                                .frame(maxWidth: .infinity, minHeight: 40)
                        }.buttonStyle(.borderedProminent).disabled(!ready)
                    }
                }
                .padding(16)
                .background(.bar)
            }
            .disabled(busy)
            .navigationTitle(L10n.text(.protect_title))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar { ToolbarItem(placement:.cancellationAction) { Button(L10n.text(.ui_cancel)) { dismiss() }.disabled(busy) } }
            .interactiveDismissDisabled(busy)
            #if os(macOS)
            .frame(minWidth: 460,idealWidth: 560,minHeight: 500,idealHeight: 680)
            #endif
            .fileImporter(isPresented:$importing,allowedContentTypes:[.data],allowsMultipleSelection:false) { selection in
                do {
                    guard let url = try selection.get().first else { return }
                    clearResult()
                    if importingCertificate {
                        let access = url.startAccessingSecurityScopedResource()
                        defer { if access { url.stopAccessingSecurityScopedResource() } }
                        let bytes = try ProtectedFileIO.read(url)
                        // Validate key usage and public-key type before accepting a recipient.
                        _ = try CertificateFileProtection.encrypt(Data(),certificate:bytes)
                        certificate = bytes; certificateName = url.lastPathComponent; identity = nil; identities = []
                    } else { input = url }
                } catch { showError() }
            }
            .fileExporter(isPresented:$exporting,document:result,contentType:.data,defaultFilename:outputName) { outcome in
                switch outcome {
                case .success: notice = .protect_saved; isError = false; result = nil
                case .failure: showError()
                }
            }
            .fileExporter(isPresented: $exportingCertificate, document: certificateExport, contentType: .data, defaultFilename: certificateExportName) { outcome in
                certificateExport = nil
                switch outcome {
                case .success: notice = .protect_saved; isError = false
                case .failure: showError()
                }
            }
            .confirmationDialog(L10n.text(.protect_remove_confirm),isPresented:$confirmRemoval,titleVisibility:.visible) {
                Button(L10n.text(.protect_remove),role:.destructive) { process() }
            } message: { Text((input?.lastPathComponent ?? "") + "\n\n" + L10n.text(.protect_removal_warning)) }
            .onChange(of:operation) { _, _ in clearResult(); password = ""; confirmation = ""; pin = "" }
            .onChange(of:method) { _, _ in clearResult(); password = ""; confirmation = ""; pin = "" }
            .onChange(of:password) { _, _ in if !busy && result != nil { clearResult() } }
            .onChange(of:confirmation) { _, _ in if !busy && result != nil { clearResult() } }
            .onChange(of:pin) { _, _ in if !busy && result != nil { clearResult() } }
            .onChange(of:scenePhase) { _, phase in if phase != .active { password = ""; confirmation = ""; pin = "" } }
            #if DEBUG
            .onAppear {
                if model.isScreenshotCapture {
                    let scenario = ProcessInfo.processInfo.environment["MSIGN_DEMO_SCENARIO"] ?? ""
                    if scenario.hasPrefix("protect-") {
                        input = URL(fileURLWithPath: "/FictionalDocuments/Contract.pdf")
                        operation = scenario.contains("remove") ? 2 : scenario.contains("decrypt") ? 1 : 0
                        method = scenario.contains("certificate") ? 1 : 0
                    }
                }
            }
            #endif
            .onDisappear { password = ""; confirmation = ""; pin = ""; result = nil }
        }
    }
    private var requirementsKey: L10n.Key {
        if method == 0 { return operation == 0 ? .protect_password_encrypt_guide : .protect_password_decrypt_guide }
        return operation == 0 ? .protect_certificate_encrypt_guide : .protect_certificate_decrypt_guide
    }
    private var helpKey: L10n.Key {
        if method == 0 { return operation == 0 ? .protect_password_encrypt_help : .protect_password_decrypt_help }
        return operation == 0 ? .protect_certificate_encrypt_help : .protect_certificate_decrypt_help
    }
    private var outputName: String {
        let name = input?.lastPathComponent ?? "document"
        if operation == 0 { return name + (method == 0 ? PasswordFileProtection.suffix : CertificateFileProtection.suffix) }
        for suffix in [PasswordFileProtection.suffix,CertificateFileProtection.suffix] where name.hasSuffix(suffix) {
            return "decrypted-" + String(name.dropLast(suffix.count))
        }
        return "decrypted-" + name
    }
    private func clearResult() { result = nil; notice = nil; isError = false }
    private func showError() { notice = .protect_error; isError = true }
    private func readCard() {
        guard !model.demoMode, let reader = model.selectedCard?.reader else { return }
        busy = true; clearResult(); identity = nil; identities = []; certificate = nil; certificateName = ""
        let service = model.service
        Task {
            do {
                let found = try await Task.detached { try service.withCard(reader:reader) { try $0.encryptionIdentities() } }.value
                guard let first = found.first else { notice = .protect_no_key; isError = true; busy = false; return }
                identities = found; identity = first; identityReader = reader; certificate = first.certificate; certificateName = first.label
            } catch { showError() }
            busy = false
        }
    }
    private func process() {
        guard let url = input, ready else { return }
        busy = true; clearResult()
        let operation = operation, method = method, secret = password, cardPIN = pin
        let certificate = certificate, identity = identity, reader = identityReader, service = model.service
        password = ""; confirmation = ""; pin = ""
        Task {
            do {
                let output: Data? = try await Task.detached {
                    let access = url.startAccessingSecurityScopedResource()
                    defer { if access { url.stopAccessingSecurityScopedResource() } }
                    if operation == 2 { try ProtectedFileIO.overwriteAndRemove(url); return nil }
                    let bytes = try ProtectedFileIO.read(url)
                    if method == 0 {
                        return try operation == 0 ? PasswordFileProtection.encrypt(bytes,password:secret) : PasswordFileProtection.decrypt(bytes,password:secret)
                    }
                    if operation == 0, let certificate { return try CertificateFileProtection.encrypt(bytes,certificate:certificate) }
                    guard let identity else { throw FileProtectionError.cannotDecrypt }
                    return try service.withCard(reader:reader) { try $0.decryptFile(bytes,identity:identity,pin:cardPIN) }
                }.value
                if let output { result = ProtectedExport(data:output); notice = .protect_ready }
                else { notice = .protect_removed; input = nil }
            } catch is CardError { notice = .protect_pin_failure; isError = true }
            catch { showError() }
            busy = false
        }
    }
}
private struct ProtectedExport: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }
    let data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents:data) }
}
