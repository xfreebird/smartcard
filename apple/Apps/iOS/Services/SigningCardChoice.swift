import SwiftUI

/// NFC keeps a compact choice; the reader exposes its live setup and card selection inline.
struct SigningCardChoice: View {
    @Environment(AppModel.self) private var model
    @Environment(\.horizontalSizeClass) private var sizeClass
    var size: CardSelector.Size = .phone
    var compact = false
    var signing = false
    var inlineReaderCards = false
    @State private var showsGuide = false
    @State private var showsReaderGuide = false
    @State private var showsReaderCards = false
    private var nfc: Bool { model.signingMethod == .nfc }
    private var readerHero: Bool { signing && !compact && !nfc }

    var body: some View {
        VStack(spacing: compact ? 12 : (signing && sizeClass == .compact ? 16 : 24)) {
            if !compact {
                if signing {
                    // Both methods occupy the same space, including the reader's carousel dots.
                    ZStack {
                        SigningCardIllustration(nfc: nfc)
                            .opacity(readerHero ? 0 : 1)
                            CardSelector(size: sizeClass == .compact ? .phone : .large)
                                .frame(maxWidth: 400)
                                .opacity(readerHero ? 1 : 0)
                                .allowsHitTesting(readerHero)
                                .accessibilityHidden(!readerHero)
                                .accessibilityIdentifier("signing.reader.cards")
                    }
                }
                VStack(spacing: 10) {
                    Text(L10n.text(signing ? .guided_start : .guided_card_title))
                        .font(signing && sizeClass == .compact ? .title2.bold() : .largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text(L10n.text(signing ? .guided_start_body : .guided_card_body))
                        .font(.body).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }.fixedSize(horizontal: false, vertical: true)
            }
            VStack(spacing: 0) {
                Menu {
                    Button { model.selectSigningMethod(.nfc) } label: {
                        Label(L10n.text(.guided_contactless), systemImage: "wave.3.right")
                    }.disabled(!model.nfcAvailable).accessibilityIdentifier("signing.method.nfc")
                    Button { model.selectSigningMethod(.reader) } label: {
                        Label(L10n.text(.guided_reader), systemImage: "creditcard")
                    }.accessibilityIdentifier("signing.method.reader")
                } label: {
                    choiceRow(icon: nfc ? "wave.3.right" : "creditcard",
                              title: L10n.text(nfc ? .guided_contactless : .guided_reader),
                              caption: L10n.text(.guided_method_caption))
                }.accessibilityIdentifier("signing.method")
                .accessibilityLabel(L10n.text(nfc ? .guided_contactless : .guided_reader))
                .disabled(!model.canChangeSigningMethod)

                if nfc && !model.knownSigningCertificates.isEmpty && !(signing && !compact) {
                    Divider().padding(.leading, 56)
                    Menu {
                        Button(L10n.text(.nfc_use_another_card)) { model.useAnotherNFCCard() }
                            .accessibilityIdentifier("signing.nfc.anotherCard")
                        ForEach(model.knownSigningCertificates, id: \.sha1Hex) { certificate in
                            Button("\(certificate.holder) · \(certificate.sha1Hex.suffix(8))") {
                                model.selectNFCCard(certificate.sha1Hex)
                            }
                            .accessibilityIdentifier("signing.nfc.identity.\(certificate.sha1Hex)")
                        }
                    } label: {
                        choiceRow(icon: "person.crop.circle", title: model.nfcCertificate?.holder ?? L10n.text(.nfc_card_any))
                    }.disabled(!model.canChangeSigningMethod).accessibilityIdentifier("signing.nfc.card")
                } else if !nfc && !inlineReaderCards && !readerHero {
                    Divider().padding(.leading, 56)
                    Button { showsReaderCards = true } label: {
                        choiceRow(icon: model.status.cardPresent ? "person.crop.circle" : "cable.connector",
                                  title: model.certificate?.holder ?? model.status.title,
                                  caption: model.certificate == nil ? nil : model.selectedCard?.reader)
                    }.disabled(!model.canChangeSigningMethod).accessibilityIdentifier("signing.reader.cards")
                }
            }
            .background(Theme.surfaceRaised, in: RoundedRectangle(cornerRadius: 22))
            .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.primary.opacity(0.04)))
            .buttonStyle(.plain)
            if !nfc && inlineReaderCards {
                VStack(spacing: 10) {
                    CardSelector(size: size, showsConnectionHelp: false)
                        .accessibilityIdentifier("signing.reader.cards")
                    if model.displayedCards.count > 1 {
                        Text(L10n.text(.guided_reader_swipe))
                            .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                }
            }
            Button { if nfc { showsGuide = true } else { showsReaderGuide = true } } label: {
                Label(L10n.text(.nfc_how_it_works), systemImage: "questionmark.circle")
                    .font(.subheadline).frame(minHeight: 44)
            }.tint(Theme.brand).accessibilityIdentifier("signing.nfc.help")
        }
        .frame(maxWidth: 560)
        .sheet(isPresented: $showsGuide) { NFCGuideView() }
        .sheet(isPresented: $showsReaderGuide) { ConnectionGuideView() }
        .sheet(isPresented: $showsReaderCards) {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 16) {
                        CardSelector(size: .large)
                        if model.displayedCards.count > 1 {
                            Text(L10n.text(.guided_reader_swipe))
                                .font(.subheadline).foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }.padding(24)
                }
                    .navigationTitle(L10n.text(.settings_card_reader)).navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.text(.ui_done)) { showsReaderCards = false }
                    } }
            }.presentationDetents([.medium, .large])
        }
    }

    private func choiceRow(icon: String, title: String, caption: String? = nil) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon).font(.title3).foregroundStyle(Theme.brand).frame(width: 26)
            VStack(alignment: .leading, spacing: 3) {
                if let caption { Text(caption).font(.caption).foregroundStyle(.secondary) }
                Text(title).font(.body.weight(.medium)).foregroundStyle(.primary).multilineTextAlignment(.leading)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.down").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
        }.padding(16).frame(minHeight: signing && !compact ? 88 : 62).contentShape(Rectangle())
    }
}

/// The same card, palette and proportions for NFC and a physical reader.

struct NFCSymbol: View {
    var body: some View { SigningCardIllustration() }
}

struct NFCGuideView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            NFCGuideContent()
            .navigationTitle(L10n.text(.nfc_how_it_works))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) {
                Button(L10n.text(.ui_done)) { dismiss() }.accessibilityIdentifier("nfc.help.close")
            } }
        }
        .accessibilityIdentifier("nfc.help")
    }
}

struct NFCGuideContent: View {
    var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    NFCSymbol().frame(maxWidth: .infinity)
                    step(1, .nfc_guide_document, .nfc_guide_document_body)
                    step(2, .nfc_guide_pin, .nfc_guide_pin_body)
                    step(3, .nfc_guide_tap, .nfc_guide_tap_ios)
                    Label(L10n.text(.nfc_guide_result), systemImage: "checkmark.circle")
                        .font(.subheadline).foregroundStyle(.secondary)
                }.padding(24).frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
            }
    }
    private func step(_ number: Int, _ title: L10n.Key, _ detail: L10n.Key) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Text("\(number)").font(.headline).foregroundStyle(Color.accentColor)
                .frame(width: 32, height: 32).background(Color.accentColor.opacity(0.1), in: Circle())
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.text(title)).font(.headline)
                Text(L10n.text(detail)).font(.body).foregroundStyle(.secondary)
            }
        }.accessibilityElement(children: .combine)
    }
}

struct SigningHelpPage: View {
    @Environment(AppModel.self) private var model
    var body: some View {
        Group {
            if model.signingMethod == .nfc { NFCGuideContent() }
            else { ReaderGuideContent() }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle(L10n.text(.nfc_how_it_works))
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityIdentifier("settings.help.page")
    }
}
