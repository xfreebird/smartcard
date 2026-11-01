import SwiftUI
import MoldSignKit

/// Horizontally paged identity cards. Selection follows the visible page; dots and VoiceOver
/// provide the same selection without gestures. All geometry is derived from the card width.
struct CardSelector: View {
    enum Size {
        case compact, large, phone
        var maxWidth: CGFloat? {
            switch self {
            case .compact: return 288
            case .large: return 400
            case .phone: return nil
            }
        }
    }

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var size: Size = .large
    @State private var width: CGFloat = 288
    @State private var visibleReader: String?
    @State private var userIsScrolling = false
    @State private var selectionPending = false
    @State private var selectionCommit: Task<Void, Never>?
    #if os(macOS)
    @State private var hoveringCard = false
    #endif
    private var cardWidth: CGFloat {
        #if os(macOS)
        // Reserve space for hover controls outside the card when several readers exist.
        let gutters: CGFloat = model.cards.count > 1 ? 88 : 8
        return max(120, min(size.maxWidth ?? .infinity, width - gutters))
        #else
        return max(120, width - 8)
        #endif
    }
    private var selectorMaxWidth: CGFloat? {
        #if os(macOS)
        return size == .compact ? size.maxWidth.map { $0 + (model.cards.count > 1 ? 88 : 0) } : nil
        #else
        return size.maxWidth
        #endif
    }
    private var sideInset: CGFloat { max(4, (width - cardWidth) / 2) }
    private var cardHeight: CGFloat { cardWidth / IDCardFace.ratio }
    private var selectedIndex: Int { model.cards.firstIndex { $0.reader == model.selectedCard?.reader } ?? 0 }

    var body: some View {
        VStack(spacing: 10) {
            if model.cards.isEmpty {
                EmptyCardFace(status: model.status, size: size)
                    .frame(height: cardHeight)
            } else {
                #if os(iOS)
                TabView(selection: Binding(get: { model.selectedCard?.reader ?? "" }, set: { reader in
                    // TabView may write back the temporary fallback after a reader disappears.
                    if reader != model.selectedCard?.reader { model.selectCard(reader) }
                })) {
                    ForEach(model.cards) { card in
                        cardFace(card)
                            .padding(.bottom, model.cards.count > 1 ? 32 : 0)
                            .tag(card.reader)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: model.cards.count > 1 ? .always : .never))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .frame(height: cardHeight + (model.cards.count > 1 ? 36 : 8))
                .allowsHitTesting(model.currentStep == nil)
                #else
                ScrollViewReader { proxy in
                    ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(model.cards) { card in
                            cardFace(card)
                                .frame(width: width)
                                .id(card.reader)
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.vertical, 4)
                }
                .contentMargins(.horizontal, 0, for: .scrollContent)
                .scrollIndicators(.hidden)
                .modifier(CardPaging(interactionChanged: interactionChanged))
                .scrollPosition(id: $visibleReader, anchor: .center)
                .scrollDisabled(model.currentStep != nil)
                .frame(height: cardHeight + 8)
                .overlay {
                    if model.cards.count > 1 {
                        HStack {
                            carouselArrow(-1)
                            Spacer()
                            carouselArrow(1)
                        }
                        .padding(.horizontal, 4)
                        .opacity(hoveringCard ? 1 : 0)
                        .allowsHitTesting(hoveringCard)
                        .accessibilityHidden(!hoveringCard)
                    }
                }
                .onHover { hoveringCard = $0 }
                .onAppear { visibleReader = model.selectedCard?.reader }
                .task(id: width) {
                    // Content margins and card width are measured after the first layout. Restore the
                    // selected item with the native proxy once that geometry is available.
                    let target = model.selectedCard?.reader
                    await Task.yield()
                    guard !Task.isCancelled, let target else { return }
                    proxy.scrollTo(target, anchor: .center)
                }
                .onChange(of: visibleReader) { _, reader in
                    if selectionPending && !userIsScrolling { commitSelectionWhenSettled() }
                }
                .onChange(of: model.selectedCard?.reader) { _, reader in
                    // During a swipe the binding already contains this reader. Only explicit selection
                    // changes (keyboard, card replacement) need an imperative scroll.
                    guard !userIsScrolling, !selectionPending, visibleReader != reader, let reader else { return }
                    withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
                        visibleReader = reader
                        proxy.scrollTo(reader, anchor: .center)
                    }
                }
                }
                #endif
                #if os(macOS)
                if model.cards.count > 1 {
                    HStack(spacing: 0) {
                        // A reader may disappear while SwiftUI is still updating its old
                        // children. Capture each card's value rather than a live array index.
                        ForEach(model.cards) { card in
                            Button {
                                guard model.currentStep == nil,
                                      model.cards.contains(where: { $0.reader == card.reader }) else { return }
                                model.selectCard(card.reader)
                            } label: {
                                Circle()
                                    .fill(card.reader == model.selectedCard?.reader ? Color.accentColor : Color.secondary.opacity(0.3))
                                    .frame(width: 7, height: 7)
                                    .frame(width: 20, height: 20)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .disabled(model.currentStep != nil)
                            .accessibilityLabel(IDCardFace.accessibilityLabel(card))
                            .accessibilityAddTraits(card.reader == model.selectedCard?.reader ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 2)
                }
                #endif
            }
        }
        .frame(maxWidth: selectorMaxWidth ?? .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .frame(maxWidth: .infinity)
        .onDisappear { selectionCommit?.cancel(); userIsScrolling = false; selectionPending = false }
        .onKeyPress(.leftArrow) { move(-1); return .handled }
        .onKeyPress(.rightArrow) { move(1); return .handled }
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: move(1)
            case .decrement: move(-1)
            @unknown default: break
            }
        }
        #if os(iOS)
        .sensoryFeedback(.selection, trigger: model.selectedCard?.reader)
        #endif
    }

    private func cardFace(_ card: CardSlot) -> some View {
        IDCardFace(card: card, busy: model.currentStep != nil && card.reader == model.selectedCard?.reader,
                   inUse: model.cards.count > 1 && card.reader == model.selectedCard?.reader)
            .frame(width: cardWidth, height: cardHeight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(IDCardFace.accessibilityLabel(card))
            .accessibilityAddTraits(card.reader == model.selectedCard?.reader ? .isSelected : [])
            .contextMenu {
                Button { model.rereadCards() } label: { Label(L10n.text(.ui_read_the_card_again), systemImage: "arrow.clockwise") }
            }
    }

    #if os(macOS)
    private func carouselArrow(_ direction: Int) -> some View {
        let title = L10n.text(direction < 0 ? .ui_previous_card : .ui_next_card)
        return Button { move(direction) } label: {
            Image(systemName: direction < 0 ? "chevron.left" : "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 32, height: 32)
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().strokeBorder(Color.primary.opacity(0.12)))
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(model.currentStep != nil || (direction < 0 ? selectedIndex == 0 : selectedIndex >= model.cards.count - 1))
        .accessibilityLabel(title)
        .help(title)
    }
    #endif

    private func interactionChanged(_ active: Bool) {
        if active {
            selectionCommit?.cancel()
            userIsScrolling = true
            selectionPending = true
        } else if selectionPending {
            userIsScrolling = false
            commitSelectionWhenSettled()
        }
    }

    private func commitSelectionWhenSettled() {
        selectionCommit?.cancel()
        selectionCommit = Task { @MainActor in
            if #available(iOS 18.0, macOS 15.0, *) {
                await Task.yield()
            } else {
                // Older iOS has no native scroll-phase callback; debounce its final binding changes.
                try? await Task.sleep(for: .milliseconds(180))
            }
            guard !Task.isCancelled, !userIsScrolling else { return }
            if let reader = visibleReader, model.currentStep == nil,
               model.cards.contains(where: { $0.reader == reader }) { model.selectCard(reader) }
            selectionPending = false
        }
    }

    private func move(_ delta: Int) {
        guard !model.cards.isEmpty, model.currentStep == nil else { return }
        let next = min(max(selectedIndex + delta, 0), model.cards.count - 1)
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) {
            model.selectCard(model.cards[next].reader)
        }
    }
}

/// Use the native behavior directly so SwiftUI registers view-aligned scroll targets as well as snapping.
private struct CardPaging: ViewModifier {
    let interactionChanged: (Bool) -> Void
    @State private var legacyHorizontalDrag = false

    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 26.0, macOS 26.0, *) {
            #if compiler(>=6.2)
            content.scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne, anchor: .center))
                .onScrollPhaseChange { _, phase in phaseChanged(phase) }
            #else
            // Xcode 16 can target older systems but does not contain the iOS 26 anchor overload.
            content.scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
                .onScrollPhaseChange { _, phase in phaseChanged(phase) }
            #endif
        } else if #available(iOS 18.0, macOS 15.0, *) {
            content.scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
                .onScrollPhaseChange { _, phase in phaseChanged(phase) }
        } else {
            content.scrollTargetBehavior(.viewAligned(limitBehavior: .always))
                .simultaneousGesture(DragGesture(minimumDistance: 4)
                    .onChanged { value in
                        if abs(value.translation.width) > abs(value.translation.height) {
                            legacyHorizontalDrag = true
                            interactionChanged(true)
                        }
                    }
                    .onEnded { _ in
                        if legacyHorizontalDrag { legacyHorizontalDrag = false; interactionChanged(false) }
                    })
        }
    }

    @available(iOS 18.0, macOS 15.0, *)
    private func phaseChanged(_ phase: ScrollPhase) {
        switch phase {
        case .tracking, .interacting, .decelerating: interactionChanged(true)
        case .idle: interactionChanged(false)
        default: break
        }
    }
}

/// One card drawn as the Moldovan identity card (docs/10 §0.2b): an illustration of the user's own card with
/// certificate data only (no photo, coat of arms, document number or IDNP). Fixed colors in light and dark, like a
/// Wallet pass. Every length is relative to the card width so it scales from the popover to a phone.
struct IDCardFace: View {
    static let ratio: CGFloat = (1 + sqrt(5)) / 2
    static let cornerRatio: CGFloat = 0.045
    static let ink = Color(rgb: 0x1E2230)
    private static let muted = Color(rgb: 0x5A6070)
    private static let navy = Color(rgb: 0x283A8C)
    private static let burgundy = Color(rgb: 0x9E2A3F)

    let card: CardSlot
    var busy = false
    /// Field values stop at 0.88 W so they never run under the disclosure button.
    var reservesDisclosure = false
    /// In the expanded list: the status strip says the card is the one used for signing.
    var inUse = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            ZStack(alignment: .topLeading) {
                Canvas { context, size in Self.drawPaper(context, size, hueShift: hueShift) }
                heading("REPUBLICA MOLDOVA", "REPUBLIC OF MOLDOVA", color: Self.navy, w: w)
                    .frame(width: w * 0.32, alignment: .leading)
                    .offset(x: w * 0.045, y: h * 0.055)
                heading("CARTE DE IDENTITATE", "IDENTITY CARD", color: Self.burgundy, w: w)
                    .frame(width: w * 0.36, alignment: .leading)
                    .offset(x: w * 0.465, y: h * 0.055)
                Chip()
                    .frame(width: w * 0.10, height: w * 0.075)
                    .offset(x: w * 0.855, y: (h - w * 0.075) / 2)
                fields(w: w, h: h)
                status(w: w)
                    .frame(width: w * 0.635, alignment: .leading)
                    .offset(x: w * 0.32, y: h * 0.835)
            }
        }
        .aspectRatio(Self.ratio, contentMode: .fit)
        .clipShape(shape)
        .overlay(shape.strokeBorder(.black.opacity(0.14), lineWidth: 0.5))
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2.5)
        .help(card.reader)
    }

    private var shape: some InsettableShape {
        GeometryShape(cornerRatio: Self.cornerRatio)
    }

    // MARK: Text

    private func heading(_ first: String, _ second: String, color: Color, w: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: w * 0.004) {
            Text(verbatim: first).font(.system(size: w * 0.034, weight: .bold)).tracking(w * 0.0012)
            Rectangle().frame(height: 0.6).opacity(0.55)
            Text(verbatim: second).font(.system(size: w * 0.025, weight: .medium))
            Rectangle().frame(height: 0.6).opacity(0.55)
        }
        .foregroundStyle(color)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }

    @ViewBuilder private func fields(w: CGFloat, h: CGFloat) -> some View {
        let cert = card.certificate
        let nameWidth = w * 0.50
        field(L10n.text(.ui_surname), cert?.surname, w: w)
            .frame(width: nameWidth, alignment: .leading)
            .offset(x: w * 0.32, y: h * 0.29)
        field(L10n.text(.ui_given_names), cert?.givenNames, w: w)
            .frame(width: nameWidth, alignment: .leading)
            .offset(x: w * 0.32, y: h * 0.46)
        field(L10n.text(.ui_valid_until_2), cert.map { $0.notAfter.map(Self.cardDate) ?? "—" }, w: w)
            .frame(width: w * 0.32, alignment: .leading)
            .offset(x: w * 0.32, y: h * 0.63)
        field(L10n.text(.ui_issuer), cert?.issuerName, w: w)
            .frame(width: w * 0.29, alignment: .leading)
            .offset(x: w * 0.665, y: h * 0.63)
    }

    private func field(_ label: String, _ value: String?, w: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: w * 0.004) {
            Text(verbatim: label)
                .font(.system(size: w * 0.026))
                .italic()
                .foregroundStyle(Self.muted)
            Text(verbatim: (value?.isEmpty == false ? value! : "—").uppercased())
                .font(.system(size: w * 0.047, weight: .semibold))
                .foregroundStyle(Self.ink)
                .redacted(reason: value == nil ? .placeholder : [])
        }
        .lineLimit(1)
        .minimumScaleFactor(0.55)
    }

    private func status(w: CGFloat) -> some View {
        let (text, color, isProblem) = statusLine
        let checked = inUse && !isProblem && !busy && card.certificate != nil
        return HStack(spacing: w * 0.015) {
            if checked {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: w * 0.036, weight: .semibold))
                    .foregroundStyle(Color(rgb: 0x2350D8))
            } else {
                Circle().fill(color).frame(width: w * 0.024, height: w * 0.024)
            }
            Text(checked ? L10n.text(.ui_used_for_signing) : text)
                .foregroundStyle(isProblem ? color : checked ? Color(rgb: 0x2350D8) : Self.ink)
                .font(.system(size: w * 0.033, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private var statusLine: (String, Color, Bool) {
        if let problem = card.problem { return (problem, Color(rgb: 0xC62828), true) }
        if card.certificate == nil { return (L10n.text(.ui_reading_the_card), Color(rgb: 0xD08A00), false) }
        if busy { return (L10n.text(.ui_signing), Color(rgb: 0x2350D8), false) }
        return (L10n.text(.ui_ready_to_sign), Color(rgb: 0x1E9E55), false)
    }

    // MARK: Drawing

    /// Guilloche hue nudged per card (±20°, from the certificate SHA-1) so two cards differ at a glance.
    private var hueShift: Double {
        let byte = card.certificate.flatMap { UInt8($0.sha1Hex.prefix(2), radix: 16) } ?? 128
        return Double(byte) / 255 * 40 - 20
    }

    private static func drawPaper(_ context: GraphicsContext, _ size: CGSize, hueShift: Double) {
        let w = size.width, h = size.height
        let line = max(0.5, w / 520)
        context.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .linearGradient(Gradient(colors: [Color(rgb: 0xF4EAF0), Color(rgb: 0xECEFF7), Color(rgb: 0xF6F0E1)]),
                                           startPoint: .zero, endPoint: CGPoint(x: w, y: h)))

        // guilloche: two families of sine waves woven across the card
        let rose = Color(hue: (317 + hueShift) / 360, saturation: 0.32, brightness: 0.74)
        let blue = Color(hue: (222 + hueShift) / 360, saturation: 0.34, brightness: 0.84)
        for family in 0..<2 {
            for i in 0..<12 {
                var wave = Path()
                let base = h * (0.03 + CGFloat(i) * 0.085)
                let amplitude = h * (family == 0 ? 0.04 : 0.03)
                let period = w * (family == 0 ? 0.55 : 0.8)
                let phase = CGFloat(i) * 0.35 + (family == 0 ? 0 : .pi)
                for x in stride(from: CGFloat(0), through: w, by: 2) {
                    let point = CGPoint(x: x, y: base + amplitude * sin(2 * .pi * x / period + phase))
                    if x == 0 { wave.move(to: point) } else { wave.addLine(to: point) }
                }
                context.stroke(wave, with: .color((i.isMultiple(of: 2) ? rose : blue).opacity(family == 0 ? 0.35 : 0.22)),
                               lineWidth: line)
            }
        }

        // rosette behind the fields
        let center = CGPoint(x: w * 0.78, y: h * 0.62)
        let petal = Path(ellipseIn: CGRect(x: -w * 0.22, y: -w * 0.075, width: w * 0.44, height: w * 0.15))
        for k in 0..<8 {
            let transform = CGAffineTransform(translationX: center.x, y: center.y).rotated(by: CGFloat(k) * .pi / 8)
            context.stroke(petal.applying(transform), with: .color(Color(rgb: 0xC9B48A).opacity(0.3)), lineWidth: line)
        }

        // neutral shield between the headings (never the state coat of arms)
        let s = CGRect(x: w * 0.394, y: h * 0.06, width: w * 0.05, height: w * 0.06)
        var shield = Path()
        shield.move(to: CGPoint(x: s.minX, y: s.minY))
        shield.addLine(to: CGPoint(x: s.maxX, y: s.minY))
        shield.addLine(to: CGPoint(x: s.maxX, y: s.minY + s.height * 0.5))
        shield.addQuadCurve(to: CGPoint(x: s.midX, y: s.maxY), control: CGPoint(x: s.maxX, y: s.minY + s.height * 0.86))
        shield.addQuadCurve(to: CGPoint(x: s.minX, y: s.minY + s.height * 0.5), control: CGPoint(x: s.minX, y: s.minY + s.height * 0.86))
        shield.closeSubpath()
        context.fill(shield, with: .color(Color(rgb: 0xE9D9B4).opacity(0.7)))
        context.stroke(shield, with: .color(Color(rgb: 0x8C6A3A)), lineWidth: max(0.6, w / 400))
        let inner = shield.applying(CGAffineTransform(translationX: s.midX, y: s.midY).scaledBy(x: 0.62, y: 0.62)
            .translatedBy(x: -s.midX, y: -s.midY))
        context.stroke(inner, with: .color(Color(rgb: 0x8C6A3A).opacity(0.6)), lineWidth: line)

        // portrait frame with a neutral silhouette
        // Match the portrait proportions and silhouette used by the Linux card.
        let photo = CGRect(x: w * 0.045, y: h * 0.30, width: w * 0.20, height: w * 0.20 * 5 / 3)
        let frame = Path(roundedRect: photo, cornerRadius: w * 0.02, style: .continuous)
        context.fill(frame, with: .linearGradient(Gradient(colors: [Color(rgb: 0xD9DCE3), Color(rgb: 0xBFC4CF)]),
                                                  startPoint: CGPoint(x: photo.midX, y: photo.minY),
                                                  endPoint: CGPoint(x: photo.midX, y: photo.maxY)))
        var portrait = context
        portrait.clip(to: frame)
        let unit = photo.width
        let headCenterY = photo.minY + photo.height * 0.34
        let head = CGRect(x: photo.midX - unit * 0.23, y: headCenterY - unit * 0.23,
                          width: unit * 0.46, height: unit * 0.46)
        var person = Path(ellipseIn: head)
        let shoulderY = headCenterY + unit * 0.31
        let shoulderBase = shoulderY + unit * 0.36
        var torso = Path()
        torso.move(to: CGPoint(x: photo.midX - unit * 0.46, y: shoulderBase))
        torso.addCurve(to: CGPoint(x: photo.midX, y: shoulderY),
                       control1: CGPoint(x: photo.midX - unit * 0.44, y: shoulderY + unit * 0.11),
                       control2: CGPoint(x: photo.midX - unit * 0.23, y: shoulderY))
        torso.addCurve(to: CGPoint(x: photo.midX + unit * 0.46, y: shoulderBase),
                       control1: CGPoint(x: photo.midX + unit * 0.23, y: shoulderY),
                       control2: CGPoint(x: photo.midX + unit * 0.44, y: shoulderY + unit * 0.11))
        torso.closeSubpath()
        person.addPath(torso)
        portrait.fill(person, with: .color(Color(rgb: 0x8E95A3)))
        context.stroke(frame, with: .color(.black.opacity(0.12)), lineWidth: line)
    }

    private static func cardDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "dd MM yyyy"
        return formatter.string(from: date)
    }

    static func accessibilityLabel(_ card: CardSlot) -> String {
        guard let cert = card.certificate else { return L10n.text(.ui_card_in_value_reading, card.reader) }
        let until = cert.notAfter.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "—"
        if let problem = card.problem { return "\(cert.holder), \(problem)" }
        return L10n.text(.ui_value_identity_card_valid_until_value, cert.holder, until)
    }
}

/// Rounded rectangle whose corner radius follows the width (ID-1 corners scale with the card).
private struct GeometryShape: InsettableShape {
    var cornerRatio: CGFloat
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: inset, dy: inset)
        return Path(roundedRect: r, cornerRadius: rect.width * cornerRatio, style: .continuous)
    }

    func inset(by amount: CGFloat) -> GeometryShape {
        var copy = self
        copy.inset += amount
        return copy
    }
}

/// Gold contact chip.
private struct Chip: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width, h = geo.size.height
            RoundedRectangle(cornerRadius: w * 0.16, style: .continuous)
                .fill(LinearGradient(colors: [Color(red: 0.98, green: 0.84, blue: 0.45), Color(red: 0.80, green: 0.62, blue: 0.22)],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay {
                    Path { p in
                        // Eight regions: three pads on either side and two in the middle.
                        let left = w * 0.32, right = w * 0.68
                        p.move(to: CGPoint(x: left, y: 0)); p.addLine(to: CGPoint(x: left, y: h))
                        p.move(to: CGPoint(x: right, y: 0)); p.addLine(to: CGPoint(x: right, y: h))
                        for y in [CGFloat(1) / 3, CGFloat(2) / 3] {
                            p.move(to: CGPoint(x: 0, y: h * y)); p.addLine(to: CGPoint(x: left, y: h * y))
                            p.move(to: CGPoint(x: right, y: h * y)); p.addLine(to: CGPoint(x: w, y: h * y))
                        }
                        p.move(to: CGPoint(x: left, y: h * 0.5)); p.addLine(to: CGPoint(x: right, y: h * 0.5))
                    }
                    .stroke(Color(red: 0.55, green: 0.40, blue: 0.10).opacity(0.55), lineWidth: 0.8)
                }
        }
        .accessibilityHidden(true)
    }
}

/// Empty states are cards too: no reader, reader without card, error.
struct EmptyCardFace: View {
    let status: ReaderStatus
    var size: CardSelector.Size
    @State private var showGuide = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        VStack(spacing: Theme.Space.s) {
            Image(systemName: symbol)
                .font(.system(size: size == .compact ? 26 : 32, weight: .regular))
                .foregroundStyle(isError ? Color.red : .secondary)
                .symbolEffect(.pulse, isActive: isReading)
            Text(status.title).font(.headline).multilineTextAlignment(.center)
            Text(status.subtitle).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            #if os(iOS)
            if case .noReader = status {
                Button(L10n.text(.ui_how_do_i_connect_the_reader)) { showGuide = true }
                    .font(.caption.weight(.semibold))
                    .sheet(isPresented: $showGuide) { ConnectionGuideView() }
            }
            #endif
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(isError ? Color.red.opacity(0.08) : Color.secondary.opacity(0.06), in: shape)
        .overlay(shape.strokeBorder(isError ? Color.red.opacity(0.5) : Color.secondary.opacity(0.45),
                                    style: StrokeStyle(lineWidth: 1.5, dash: isError ? [] : [7, 5])))
        .accessibilityElement(children: .contain)
    }

    private var isError: Bool {
        switch status {
        case .error, .unavailable: return true
        default: return false
        }
    }

    private var isReading: Bool {
        if case .reading = status { return true }
        return false
    }

    private var symbol: String {
        switch status {
        case .noReader: return "cable.connector"
        case .empty: return "creditcard"
        case .reading: return "creditcard.viewfinder"
        case .error, .unavailable: return "exclamationmark.triangle"
        default: return "creditcard"
        }
    }
}
