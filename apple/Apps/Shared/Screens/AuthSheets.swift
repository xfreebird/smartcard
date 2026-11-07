import SwiftUI
#if os(iOS)
import UIKit
#endif

/// docs/10 §4.3 PIN sheet: 4–8 digits, remaining attempts, optional "remember".
struct PinEntryView: View {
    let request: PinRequest
    let onSubmit: (String, Bool) -> Void
    let onCancel: () -> Void

    @State private var pin = L10n.text(.ui_)
    @State private var remember = true
    @State private var documentsExpanded = false
    @State private var keyboardVisible = false
    #if os(iOS)
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif
    private var shortViewport: Bool {
        #if os(iOS)
        verticalSizeClass == .compact
        #else
        false
        #endif
    }
    @FocusState private var focused: Bool

    private var valid: Bool { (4...8).contains(pin.count) && pin.allSatisfy(\.isNumber) }

    var body: some View {
        ScrollView {
            VStack(spacing: shortViewport ? 8 : Theme.Space.l) {
                if !shortViewport { Image(systemName: "lock.fill").font(.system(size: 28)).foregroundStyle(Theme.brand) }
                if shortViewport {
                    HStack {
                        Text(L10n.text(.ui_qscd_pin)).font(.headline)
                        Text(L10n.text(.ui_for_value, request.holder)).foregroundStyle(.secondary)
                    }.font(.subheadline)
                } else {
                    VStack(spacing: 4) {
                        Text(L10n.text(.ui_qscd_pin)).font(.title3.weight(.semibold))
                        Text(L10n.text(.ui_for_value, request.holder)).foregroundStyle(.secondary)
                    }
                }
                if !request.documentNames.isEmpty {
                    VStack(alignment: .center, spacing: 6) {
                        if shortViewport {
                            Button { documentsExpanded.toggle() } label: {
                                Label(L10n.text(.ui_pin_documents_selected_count, request.documentNames.count),
                                      systemImage: documentsExpanded ? "chevron.up" : "chevron.down")
                            }
                        } else {
                            Text(L10n.text(.ui_pin_documents_selected_count, request.documentNames.count))
                                .font(.subheadline.weight(.semibold))
                        }
                        if !shortViewport || documentsExpanded {
                            ScrollView {
                                VStack(alignment: .center, spacing: 4) {
                                    ForEach(Array(request.documentNames.enumerated()), id: \.offset) { _, name in
                                        Label(name, systemImage: "doc").lineLimit(2).truncationMode(.middle)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .center)
                            }
                            // A batch can contain more rows than fit in the sheet.  The count
                            // remains visible and the scroll indicator makes the rest explicit.
                            .frame(maxHeight: min(132, CGFloat(request.documentNames.count) * 32))
                            .scrollIndicators(.visible)
                        }
                    }
                    .font(.caption)
                }
                ZStack {
                    // Invisible key catcher behind the boxes: no system focus ring or bezel, the boxes show focus instead.
                    SecureField(L10n.text(.ui_), text: $pin)
                        .focused($focused)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .textFieldStyle(.plain)
                        .focusEffectDisabled()
                        .foregroundStyle(.clear)
                        .tint(.clear)
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                        .accessibilityLabel(L10n.text(.ui_pin))
                        .onChange(of: pin) { _, value in pin = String(value.filter(\.isNumber).prefix(8)) }
                        .onSubmit { if valid { onSubmit(pin, remember && request.canRemember) } }
                    HStack(spacing: 6) {
                        ForEach(0..<8, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(i == pin.count && focused ? Theme.brand : .secondary.opacity(0.4), lineWidth: 1.5)
                                .frame(maxWidth: 40, minHeight: 48, maxHeight: 48)
                                .overlay { if i < pin.count { Circle().frame(width: 8, height: 8) } }
                        }
                    }
                    .frame(maxWidth: 376)
                    .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
                .onTapGesture { focused = true }

                if request.canRemember {
                    Toggle(isOn: $remember) {
                        Text(L10n.text(.ui_remember_pin_touch_id_face_id))
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                    }
                }
                if let left = request.attemptsLeft {
                    Label(L10n.text(.ui_attempts_left_count, left), systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(left <= 2 ? Theme.warning : .secondary)
                        .font(.subheadline)
                }
                if !keyboardVisible {
                    HStack {
                        Button(L10n.text(.ui_cancel), role: .cancel, action: onCancel)
                            .keyboardShortcut(.cancelAction)
                        Spacer()
                        Button(L10n.text(.ui_sign)) { onSubmit(pin, remember && request.canRemember) }
                            .buttonStyle(.borderedProminent)
                            .keyboardShortcut(.defaultAction)
                            .disabled(!valid)
                    }
                }
            }
            .multilineTextAlignment(.center)
            .padding(shortViewport ? 12 : Theme.Space.xl)
            .frame(maxWidth: 480)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        #if os(macOS)
        .frame(minWidth: 340, idealHeight: 440)
        #else
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in keyboardVisible = true }
        .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in keyboardVisible = false }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Button(L10n.text(.ui_cancel), role: .cancel, action: onCancel)
                Spacer()
                Button(L10n.text(.ui_sign)) { onSubmit(pin, remember && request.canRemember) }
                    .disabled(!valid)
            }
        }
        #endif
        .onAppear { focused = true }
    }
}

/// docs/10 §4.3 consent sheet for a browser request (SEC-02).
struct ConsentView: View {
    let consent: ConsentRequest
    let onAnswer: (_ approved: Bool, _ trust: Bool) -> Void
    @State private var trust = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.l) {
            HStack(spacing: Theme.Space.m) {
                Image(systemName: "globe").font(.system(size: 26)).foregroundStyle(Theme.brand)
                VStack(alignment: .leading, spacing: 2) {
                    Text(consent.originHost).font(.title3.weight(.semibold))
                    Text(L10n.text(.ui_requests_a_signature)).foregroundStyle(.secondary)
                }
            }
            CardSurface(padding: Theme.Space.m) {
                VStack(alignment: .leading, spacing: Theme.Space.s) {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(consent.documentNames.enumerated()), id: \.offset) { _, name in
                                Label(name, systemImage: "doc.richtext")
                                    .lineLimit(2)
                                    .truncationMode(.middle)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    // Keep the sheet usable for large portal batches: the visible
                    // count/size establishes the whole request, while this list can
                    // expose every selected document without overflowing its corners.
                    .frame(maxHeight: min(132, CGFloat(consent.documentNames.count) * 34))
                    .scrollIndicators(.visible)
                    Label(consent.contentSummary, systemImage: "doc.on.doc")
                        .foregroundStyle(.secondary)
                    if let format = consent.request.format {
                        Label(signatureLabels(format), systemImage: "signature")
                    }
                    Label(L10n.text(.ui_value_mdqsign, consent.holder), systemImage: "person.text.rectangle")
                }
                .font(.subheadline)
            }
            Toggle(L10n.text(.ui_trust_this_site_for_10_minutes), isOn: $trust)
            HStack {
                Button(L10n.text(.ui_refuse), role: .cancel) { onAnswer(false, false) }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button {
                    onAnswer(true, trust)
                } label: {
                    Label(L10n.text(.ui_sign), systemImage: consent.hasStoredPIN ? "touchid" : "lock")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Theme.Space.xl)
        .frame(minWidth: 380)
    }
}
