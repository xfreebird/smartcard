import SwiftUI
import UniformTypeIdentifiers
import MoldSignKit

private enum ProtectionMethod { case password, recipient }

struct FileProtectionScreen: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    var initialURL: URL? = nil
    @State var operation = 0
    @State private var input: URL?
    @State private var password = ""
    @State private var confirmation = ""
    @State private var method = ProtectionMethod.password
    @State private var algorithm = PasswordEncryptionAlgorithm.aes256
    @State private var detected: ProtectionMethod?
    @State private var inspectedFile: URL?
    @State private var certificate: Data?
    @State private var certificateName = ""
    @State private var identities: [CardEncryptionIdentity] = []
    @State private var identity: CardEncryptionIdentity?
    @State private var identityReader: String?
    @State private var pin = ""
    @State private var importingCertificate = false
    @State private var importing = false
    @State private var confirmRemoval = false
    @State private var busy = false
    @State private var completedURL: URL?
    @State private var notice: L10n.Key?
    @State private var isError = false

    private var activeMethod: ProtectionMethod? {
        operation == 0 ? method : (inspectedFile == input ? detected : nil)
    }

    private var action: FileProtectionOperation? {
        guard input != nil else { return nil }
        if operation == 2 { return .remove }
        switch activeMethod {
        case .password:
            guard !password.isEmpty else { return nil }
            if operation == 1 { return .decrypt }
            return password == confirmation ? .encryptPassword(algorithm) : nil
        case .recipient:
            if operation == 0 { return certificate.map(FileProtectionOperation.encryptCertificate) }
            guard let identity, let identityReader, identityReader == model.selectedCard?.reader,
                  !pin.isEmpty else { return nil }
            return .decryptCertificate(reader: identityReader, identity: identity)
        case nil:
            return nil
        }
    }
    var body: some View {
        NavigationStack {
            Group {
                if let completedURL {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill").font(.system(size: 52)).foregroundStyle(.green)
                        Text(L10n.text(.protect_saved_library)).font(.title2.bold())
                        Text(completedURL.lastPathComponent).multilineTextAlignment(.center).textSelection(.enabled)
                        Text(L10n.text(operation == 0 ? .protect_encrypted : .protect_decrypted)).foregroundStyle(.secondary)
                        ShareLink(item: completedURL) {
                            Label(L10n.text(.protect_save_copy), systemImage: "square.and.arrow.up")
                        }.nativeButtonStyle()
                    }.padding(24).frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
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
                                    .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                                    .contentShape(Rectangle())
                            }.nativeButtonStyle().accessibilityIdentifier("protect.chooseFile")
                        }
                        if operation != 2 {
                            Section {
                                if operation == 0 {
                                    Picker(L10n.text(.protect_method), selection: $method) {
                                        Text(L10n.text(.protect_password)).tag(ProtectionMethod.password)
                                        Text(L10n.text(.protect_rsa_recipient)).tag(ProtectionMethod.recipient)
                                    }.pickerStyle(.segmented)
                                } else if let activeMethod {
                                    LabeledContent(L10n.text(.protect_method),
                                                   value: L10n.text(activeMethod == .password ? .protect_password : .protect_rsa_recipient))
                                }
                                if activeMethod == .password {
                                    passwordFields
                                } else if activeMethod == .recipient {
                                    recipientFields
                                }
                            } header: {
                                Text(L10n.text(.protect_access_step))
                            } footer: {
                                if operation == 1 { Text(L10n.text(.protect_detect_algorithm)) }
                            }
                            if let activeMethod {
                                Section {
                                    DisclosureGroup(L10n.text(.protect_help)) {
                                        Text(L10n.text(activeMethod == .recipient
                                                       ? (operation == 0 ? .protect_certificate_encrypt_help : .protect_certificate_decrypt_help)
                                                       : (operation == 0 ? .protect_password_encrypt_help : .protect_password_decrypt_help)))
                                        Text(L10n.text(.protect_compatibility)).font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .formStyle(.grouped)
                    #if os(iOS)
                    .contentMargins(.top, 8, for: .scrollContent)
                    .listSectionSpacing(16)
                    #endif
                    .safeAreaInset(edge: .bottom) {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.text(operation == 2 ? .protect_removal_warning : .protect_original))
                                .font(.caption).foregroundStyle(.secondary)
                            if busy { ProgressView(L10n.text(.protect_working)) }
                            if let notice {
                                Label(L10n.text(notice), systemImage: isError ? "exclamationmark.circle" : "checkmark.circle")
                                    .foregroundStyle(isError ? Color.red : Color.primary)
                                    .accessibilityIdentifier("protect.result")
                            }
                            Button {
                                if operation == 2 { confirmRemoval = true } else { process() }
                            } label: {
                                Text(L10n.text(operation == 0 ? .protect_encrypt : operation == 1 ? .protect_decrypt : .protect_remove))
                                    .frame(maxWidth: .infinity, minHeight: 40)
                            }.nativeButtonStyle(.prominent).disabled(action == nil || busy).accessibilityIdentifier("protect.submit")
                        }.padding(16).background(.bar)
                    }
                }
            }
            .disabled(busy)
            .navigationTitle(L10n.text(.protect_title))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.text(completedURL != nil || notice == .protect_removed ? .ui_done : .ui_cancel)) { dismiss() }.disabled(busy)
                }
            }
            .interactiveDismissDisabled(busy)
            #if os(macOS)
            .frame(minWidth: 460, idealWidth: 560, minHeight: 500, idealHeight: 680)
            #endif
            .fileImporter(isPresented: $importing, allowedContentTypes: [.data], allowsMultipleSelection: false) { selection in
                do {
                    guard let url = try selection.get().first else { return }
                    notice = nil
                    if importingCertificate {
                        clearRecipient()
                        let access = url.startAccessingSecurityScopedResource()
                        defer { if access { url.stopAccessingSecurityScopedResource() } }
                        let bytes = try ProtectedFileIO.read(url)
                        // Reject signing-only and non-RSA certificates at selection.
                        try CertificateFileProtection.validateRecipient(bytes)
                        certificate = bytes
                        certificateName = url.lastPathComponent
                    } else {
                        input = url
                    }
                } catch let error as CocoaError where error.code == .userCancelled {
                return
            } catch { showError() }
            }
            .confirmationDialog(L10n.text(.protect_remove_confirm), isPresented: $confirmRemoval, titleVisibility: .visible) {
                Button(L10n.text(.protect_remove), role: .destructive) { process() }
            } message: { Text((input?.lastPathComponent ?? "") + "\n\n" + L10n.text(.protect_removal_warning)) }
            .onChange(of: operation) { _, _ in clearCredentials(); clearRecipient(); notice = nil }
            .onChange(of: method) { _, _ in clearCredentials(); notice = nil }
            .onChange(of: input) { _, _ in clearCredentials() }
            .onChange(of: model.selectedCard) { _, _ in
                if identityReader != nil { clearRecipient() }
            }
            .task(id: operation == 1 ? input : nil) { await detectMethod() }
            .onChange(of: scenePhase) { _, phase in if phase != .active { clearCredentials() } }
            .onAppear { if input == nil { input = initialURL } }
            #if DEBUG
            .onAppear {
                if let preview = model.protectionPreview {
                    input = preview.input
                    operation = preview.operation
                    method = preview.usesRecipient ? .recipient : .password
                    completedURL = preview.completed
                }
            }
            #endif
            .onDisappear { clearCredentials() }
        }
    }
    @ViewBuilder private var passwordFields: some View {
        if operation == 0 {
            Picker(L10n.text(.protect_key_size), selection: $algorithm) {
                ForEach(PasswordEncryptionAlgorithm.allCases, id: \.self) { item in
                    Text(verbatim: "AES-\(item.rawValue)").tag(item)
                }
            }.pickerStyle(.menu).accessibilityIdentifier("protect.keySize")
        }
        SecureField(L10n.text(.protect_password), text: $password)
            .textContentType(operation == 0 ? .newPassword : .password)
            .textFieldStyle(.roundedBorder).labelsHidden()
            .accessibilityIdentifier("protect.password")
        if operation == 0 {
            SecureField(L10n.text(.protect_confirm_password), text: $confirmation)
                .textContentType(.newPassword).textFieldStyle(.roundedBorder).labelsHidden()
                .accessibilityIdentifier("protect.confirmPassword")
            if !confirmation.isEmpty && password != confirmation {
                Text(L10n.text(.protect_mismatch)).font(.caption).foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder private var recipientFields: some View {
        Text(L10n.text(operation == 0 ? .protect_certificate_encrypt_guide : .protect_certificate_decrypt_guide))
            .font(.callout).foregroundStyle(.secondary)
        if operation == 0 {
            Button { importingCertificate = true; importing = true } label: {
                Label(L10n.text(.protect_choose_certificate), systemImage: "person.text.rectangle")
            }.accessibilityIdentifier("protect.chooseCertificate")
        }
        Button(action: readCard) { Label(L10n.text(.protect_read_card), systemImage: "creditcard") }
            .disabled(model.demoMode || model.selectedCard == nil)
        if identities.count > 1 {
            Picker(L10n.text(.protect_recipient), selection: Binding(
                get: { identity?.fingerprint ?? "" },
                set: { value in select(identities.first { $0.fingerprint == value }) }
            )) {
                ForEach(identities, id: \.fingerprint) { item in
                    Text(item.label + " · " + item.fingerprint.suffix(8)).tag(item.fingerprint)
                }
            }
        } else if !certificateName.isEmpty {
            LabeledContent(L10n.text(.protect_recipient), value: certificateName)
        }
        if operation == 1, identity != nil {
            SecureField(L10n.text(.protect_card_pin), text: $pin)
                .textFieldStyle(.roundedBorder).labelsHidden()
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
        }
    }

    private func clearCredentials() {
        password = ""
        confirmation = ""
        pin = ""
    }

    private func clearRecipient() {
        identityReader = nil
        identities = []
        select(nil)
    }

    private func select(_ candidate: CardEncryptionIdentity?) {
        identity = candidate
        certificate = candidate?.certificate
        certificateName = candidate?.label ?? ""
        pin = ""
    }

    private func detectMethod() async {
        detected = nil
        inspectedFile = nil
        guard operation == 1, let url = input else { return }
        #if DEBUG
        if let preview = model.protectionPreview, preview.input == url {
            detected = preview.usesRecipient ? .recipient : .password
            inspectedFile = url
            return
        }
        #endif
        do {
            let recipient = try await Task.detached { try ProtectedFileIO.usesRecipientCertificate(url) }.value
            guard !Task.isCancelled, operation == 1, input == url else { return }
            detected = recipient ? .recipient : .password
            inspectedFile = url
        } catch {
            if !Task.isCancelled, operation == 1, input == url { showError() }
        }
    }

    private func readCard() {
        guard !busy, !model.demoMode, let card = model.selectedCard else { return }
        let reader = card.reader
        clearRecipient()
        notice = nil
        busy = true
        let service = model.service
        Task {
            defer { busy = false }
            do {
                let found = try await Task.detached {
                    try service.withCard(reader: reader) { try $0.encryptionIdentities() }
                }.value
                guard model.selectedCard == card else { return }
                guard let first = found.first else { notice = .protect_no_key; isError = true; return }
                identityReader = reader
                identities = found
                select(first)
            } catch { showError() }
        }
    }

    private func showError() { notice = .protect_error; isError = true }
    private func process() {
        guard let url = input, let action, !busy else { return }
        busy = true; notice = nil; isError = false
        let operation = operation, secret = activeMethod == .recipient ? pin : password
        clearCredentials()
        Task {
            do {
                let output = try await model.fileProtection.process(url, operation: action, password: secret)
                if let output {
                    model.log(ActivityItem(title: output.lastPathComponent, subtitle: L10n.text(operation == 0 ? .protect_encrypted : .protect_decrypted), ok: true, fileURL: output, signedOutput: false, protectionOperation: operation == 0 ? "encrypt" : "decrypt"))
                    completedURL = output
                } else { notice = .protect_removed; input = nil }
            } catch CardError.wrongPIN, CardError.pinBlocked {
                notice = .protect_pin_failure
                isError = true
            } catch { showError() }
            busy = false
        }
    }
}
