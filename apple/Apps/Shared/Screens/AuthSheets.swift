import SwiftUI

/// docs/10 §4.3 PIN sheet: 4–8 digits, remaining attempts, optional "remember".
struct PinEntryView: View {
    let request: PinRequest
    let onSubmit: (String, Bool) -> Void
    let onCancel: () -> Void

    @State private var pin = ""
    @State private var remember = true
    @FocusState private var focused: Bool

    private var valid: Bool { (4...8).contains(pin.count) && pin.allSatisfy(\.isNumber) }

    var body: some View {
        VStack(spacing: Theme.Space.l) {
            Image(systemName: "lock.fill").font(.system(size: 28)).foregroundStyle(Theme.brand)
            VStack(spacing: 4) {
                Text("PIN QSCD").font(.title3.weight(.semibold))
                Text("pentru \(request.holder)").foregroundStyle(.secondary)
            }
            ZStack {
                // Invisible key catcher behind the boxes: no system focus ring or bezel, the boxes show focus instead.
                SecureField("", text: $pin)
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
                    .accessibilityLabel("PIN")
                    .onChange(of: pin) { _, value in pin = String(value.filter(\.isNumber).prefix(8)) }
                    .onSubmit { if valid { onSubmit(pin, remember && request.canRemember) } }
                HStack(spacing: 6) {
                    ForEach(0..<8, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 6)
                            .strokeBorder(i == pin.count && focused ? Theme.brand : .secondary.opacity(0.4), lineWidth: 1.5)
                            .frame(width: 30, height: 38)
                            .overlay { if i < pin.count { Circle().frame(width: 8, height: 8) } }
                    }
                }
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .onTapGesture { focused = true }

            if request.canRemember {
                Toggle("Ține minte PIN-ul (Touch ID / Face ID)", isOn: $remember)
            }
            if let left = request.attemptsLeft {
                Label("Încercări rămase: \(left)", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(left <= 2 ? Theme.warning : .secondary)
                    .font(.subheadline)
            }
            HStack {
                Button("Anulează", role: .cancel, action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Semnează") { onSubmit(pin, remember && request.canRemember) }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!valid)
            }
        }
        .padding(Theme.Space.xl)
        .frame(minWidth: 340)
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
                    Text("solicită o semnătură").foregroundStyle(.secondary)
                }
            }
            CardSurface(padding: Theme.Space.m) {
                VStack(alignment: .leading, spacing: Theme.Space.s) {
                    Label(consent.request.documentName ?? String(localized: "Date de semnat"), systemImage: "doc.richtext")
                    if let format = consent.request.format {
                        Label(format, systemImage: "signature")
                    }
                    Label("\(consent.holder) · MDQSign", systemImage: "person.text.rectangle")
                }
                .font(.subheadline)
            }
            Toggle("Ai încredere în site 10 minute", isOn: $trust)
            HStack {
                Button("Refuză", role: .cancel) { onAnswer(false, false) }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button {
                    onAnswer(true, trust)
                } label: {
                    Label("Semnează", systemImage: consent.hasStoredPIN ? "touchid" : "lock")
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(Theme.Space.xl)
        .frame(minWidth: 380)
    }
}
