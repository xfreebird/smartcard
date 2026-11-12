import SwiftUI
import UniformTypeIdentifiers
import MoldSignKit

/// Password protection only: national ID cards expose signing keys, not encryption keys.
struct FileProtectionScreen: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    var initialURL: URL? = nil
    @State var operation = 0
    @State private var input: URL?
    @State private var password = ""
    @State private var confirmation = ""
    @State private var importing = false
    @State private var confirmRemoval = false
    @State private var busy = false
    @State private var completedURL: URL?
    @State private var notice: L10n.Key?
    @State private var isError = false

    private var ready: Bool {
        input != nil && !busy && (operation == 2 || (!password.isEmpty && (operation == 1 || password == confirmation)))
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
                            Button { importing = true } label: {
                                Label(input?.lastPathComponent ?? L10n.text(.protect_choose_file), systemImage: "doc.badge.plus")
                                    .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                                    .contentShape(Rectangle())
                            }.nativeButtonStyle().accessibilityIdentifier("protect.chooseFile")
                        }
                        if operation != 2 {
                            Section {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(L10n.text(.protect_password)).font(.subheadline.weight(.medium))
                                    SecureField(L10n.text(.protect_password), text: $password)
                                        .textContentType(operation == 0 ? .newPassword : .password)
                                        .textFieldStyle(.roundedBorder).labelsHidden()
                                        .accessibilityIdentifier("protect.password")
                                }.padding(.vertical, 4)
                                if operation == 0 {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(L10n.text(.protect_confirm_password)).font(.subheadline.weight(.medium))
                                        SecureField(L10n.text(.protect_confirm_password), text: $confirmation)
                                            .textContentType(.newPassword).textFieldStyle(.roundedBorder).labelsHidden()
                                            .accessibilityIdentifier("protect.confirmPassword")
                                        if !confirmation.isEmpty && password != confirmation {
                                            Text(L10n.text(.protect_mismatch)).font(.caption).foregroundStyle(.red)
                                        }
                                    }.padding(.vertical, 4)
                                }
                            } header: {
                                Text(L10n.text(.protect_access_step))
                            } footer: {
                                Text(L10n.text(operation == 0 ? .protect_password_encrypt_guide : .protect_password_decrypt_guide))
                            }
                            Section {
                                DisclosureGroup(L10n.text(.protect_help)) {
                                    Text(L10n.text(operation == 0 ? .protect_password_encrypt_help : .protect_password_decrypt_help))
                                    Text(L10n.text(.protect_compatibility)).font(.caption).foregroundStyle(.secondary)
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
                            }.nativeButtonStyle(.prominent).disabled(!ready).accessibilityIdentifier("protect.submit")
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
                    input = url; notice = nil; isError = false
                } catch { showError() }
            }
            .confirmationDialog(L10n.text(.protect_remove_confirm), isPresented: $confirmRemoval, titleVisibility: .visible) {
                Button(L10n.text(.protect_remove), role: .destructive) { process() }
            } message: { Text((input?.lastPathComponent ?? "") + "\n\n" + L10n.text(.protect_removal_warning)) }
            .onChange(of: operation) { _, _ in notice = nil; isError = false; password = ""; confirmation = "" }
            .onChange(of: scenePhase) { _, phase in if phase != .active { password = ""; confirmation = "" } }
            .onAppear { if input == nil { input = initialURL } }
            #if DEBUG
            .onAppear {
                if let preview = model.protectionPreview {
                    input = preview.input
                    operation = preview.operation
                    completedURL = preview.completed
                }
            }
            #endif
            .onDisappear { password = ""; confirmation = "" }
        }
    }
    private func showError() { notice = .protect_error; isError = true }
    private func process() {
        guard let url = input, ready else { return }
        busy = true; notice = nil; isError = false
        let operation = operation, secret = password
        password = ""; confirmation = ""
        Task {
            do {
                let action: FileProtectionOperation = operation == 0 ? .encrypt : operation == 1 ? .decrypt : .remove
                let output = try await model.fileProtection.process(url, operation: action, password: secret)
                if let output {
                    model.log(ActivityItem(title: output.lastPathComponent, subtitle: L10n.text(operation == 0 ? .protect_encrypted : .protect_decrypted), ok: true, fileURL: output, signedOutput: false, protectionOperation: operation == 0 ? "encrypt" : "decrypt"))
                    completedURL = output
                } else { notice = .protect_removed; input = nil }
            } catch { showError() }
            busy = false
        }
    }
}
