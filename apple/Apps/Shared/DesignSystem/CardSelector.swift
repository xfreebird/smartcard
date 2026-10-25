import SwiftUI
import MoldSignKit

/// The card selector (docs/10 §0.2b, UX-09/UX-10): the selected card drawn as an identity card. With several cards a
/// disclosure button at the card's right-centre expands the component, in place, into every card at the same size;
/// picking one collapses back to it. Also ←/→ (collapsed) and ↑/↓ (expanded), Space/Return to expand or confirm,
/// Escape, the context menu and VoiceOver adjust. Nothing (picker, dots, menu) sits outside the card.
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
    @State private var expanded = CardSelector.startsExpanded
    @State private var width: CGFloat = 288

    #if DEBUG
    /// Design QA: `MSIGN_DEMO_EXPANDED=1` opens the card list (debug builds only).
    private static var startsExpanded: Bool { ProcessInfo.processInfo.environment["MSIGN_DEMO_EXPANDED"] != nil }
    #else
    private static let startsExpanded = false
    #endif
    @FocusState private var focused: Bool

    private var cardWidth: CGFloat { max(120, width) }
    private var cardHeight: CGFloat { cardWidth / IDCardFace.ratio }
    private var several: Bool { model.cards.count > 1 }

    var body: some View {
        Group {
            if model.cards.isEmpty {
                EmptyCardFace(status: model.status, size: size)
                    .frame(height: cardHeight)
            } else if expanded && several {
                list
            } else if let card = model.selectedCard ?? model.cards.first {
                collapsed(card)
            }
        }
        .padding(.bottom, 4)            // room for the card's shadow
        .frame(maxWidth: size.maxWidth ?? .infinity)
        .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { width = $0 }
        .frame(maxWidth: .infinity)
        .focusable(interactions: .activate)   // like a button: in the key loop with keyboard navigation on
        .focusEffectDisabled()                // the ring is drawn on the selected card instead
        .focused($focused)
        .onKeyPress(.leftArrow) { expanded ? .ignored : move(-1) }
        .onKeyPress(.rightArrow) { expanded ? .ignored : move(+1) }
        .onKeyPress(.upArrow) { expanded ? move(-1) : .ignored }
        .onKeyPress(.downArrow) { expanded ? move(+1) : .ignored }
        .onKeyPress(.space) { toggle() }
        .onKeyPress(.return) { toggle() }
        .onKeyPress(.escape) {
            guard expanded else { return .ignored }
            setExpanded(false)
            return .handled
        }
        .onChange(of: model.cards.count) { _, count in if count < 2 { expanded = false } }
        #if os(iOS)
        .sensoryFeedback(.selection, trigger: model.selectedCard?.reader)
        #endif
    }

    // MARK: Collapsed: the selected card + disclosure

    private func collapsed(_ card: CardSlot) -> some View {
        face(card, selected: true)
            .overlay(alignment: .trailing) { if several { disclosure } }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(IDCardFace.accessibilityLabel(card))
            .accessibilityValue(several ? Text("\(selectedIndex + 1) din \(model.cards.count)") : Text(""))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment: _ = move(+1)
                case .decrement: _ = move(-1)
                @unknown default: break
                }
            }
            .accessibilityAction(named: Text("Arată toate cardurile")) { setExpanded(true) }
            .accessibilityAction(named: Text("Recitește cardul")) { model.rereadCards() }
    }

    // MARK: Expanded: every card at the same size

    private var list: some View {
        VStack(spacing: 12) {
            ForEach(model.cards) { card in
                let selected = card.reader == model.selectedCard?.reader
                Button { pick(card) } label: { face(card, selected: selected, inUse: selected) }
                    .buttonStyle(.plain)
                    .overlay(alignment: .trailing) { if selected { disclosure } }
                    .accessibilityLabel(Text("Semnează cu \(card.certificate?.holder ?? card.reader)"))
                    .accessibilityAddTraits(selected ? .isSelected : [])
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private func face(_ card: CardSlot, selected: Bool, inUse: Bool = false) -> some View {
        IDCardFace(card: card, busy: selected && model.currentStep != nil, reservesDisclosure: several, inUse: inUse)
            .frame(width: cardWidth, height: cardHeight)
            .overlay {
                if selected && (focused || expanded) {
                    RoundedRectangle(cornerRadius: cardWidth * IDCardFace.cornerRatio, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2.5)
                }
            }
            .contextMenu { contextMenu(for: card) }
    }

    /// Round chevron at the card's right-centre (centre 0.935 W, diameter 0.085 W): right = collapsed, down = expanded.
    private var disclosure: some View {
        let diameter = cardWidth * 0.085
        #if os(iOS)
        let target = max(44, diameter)      // HIG minimum touch target around the smaller visual
        #else
        let target = diameter
        #endif
        return Button { setExpanded(!expanded) } label: {
            Image(systemName: "chevron.right")
                .font(.system(size: diameter * 0.42, weight: .bold))
                .foregroundStyle(IDCardFace.ink)
                .rotationEffect(.degrees(expanded ? 90 : 0))
                .frame(width: diameter, height: diameter)
                .background(.white.opacity(0.85), in: Circle())
                .overlay(Circle().strokeBorder(.black.opacity(0.14), lineWidth: 0.5))
                .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
                .frame(width: target, height: target)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.trailing, max(0, cardWidth * 0.065 - target / 2))
        .help(expanded ? "Ascunde celelalte carduri" : "Alege cardul cu care semnezi")
        .accessibilityLabel(Text("Alege cardul (\(model.cards.count) carduri)"))
        .accessibilityValue(expanded ? Text("extins") : Text("restrâns"))
    }

    @ViewBuilder private func contextMenu(for card: CardSlot) -> some View {
        Button { model.rereadCards() } label: { Label("Recitește cardul", systemImage: "arrow.clockwise") }
        let others = model.cards.filter { $0.reader != model.selectedCard?.reader && $0.certificate != nil }
        if !others.isEmpty { Divider() }
        ForEach(others) { other in
            Button { model.selectCard(other.reader) } label: {
                Label("Semnează cu \(other.certificate?.holder ?? other.reader)", systemImage: "person.text.rectangle")
            }
        }
    }

    private var selectedIndex: Int { model.cards.firstIndex { $0.reader == model.selectedCard?.reader } ?? 0 }

    private func pick(_ card: CardSlot) {
        model.selectCard(card.reader)
        setExpanded(false)
    }

    private func setExpanded(_ value: Bool) {
        withAnimation(reduceMotion ? nil : .snappy(duration: 0.25)) { expanded = value && several }
    }

    private func toggle() -> KeyPress.Result {
        guard several else { return .ignored }
        setExpanded(!expanded)
        return .handled
    }

    private func move(_ delta: Int) -> KeyPress.Result {
        guard several else { return .ignored }
        let next = min(max(selectedIndex + delta, 0), model.cards.count - 1)
        model.selectCard(model.cards[next].reader)
        return .handled
    }
}

/// One card drawn as the Moldovan identity card (docs/10 §0.2b): an illustration of the user's own card with
/// certificate data only (no photo, coat of arms, document number or IDNP). Fixed colors in light and dark, like a
/// Wallet pass. Every length is relative to the card width so it scales from the popover to a phone.
struct IDCardFace: View {
    static let ratio: CGFloat = 1.586
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
                    .offset(x: w * 0.855, y: h * 0.06)
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
        let nameWidth = w * (reservesDisclosure ? 0.56 : 0.635)
        field("Numele/Surname", cert?.surname, w: w)
            .frame(width: nameWidth, alignment: .leading)
            .offset(x: w * 0.32, y: h * 0.29)
        field("Prenumele/Given name(s)", cert?.givenNames, w: w)
            .frame(width: nameWidth, alignment: .leading)
            .offset(x: w * 0.32, y: h * 0.46)
        field("Valabil până la/Valid until", cert.map { $0.notAfter.map(Self.cardDate) ?? "—" }, w: w)
            .frame(width: w * 0.32, alignment: .leading)
            .offset(x: w * 0.32, y: h * 0.63)
        field("Emitent/Issuer", cert?.issuerName, w: w)
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
            Text(checked ? String(localized: "Folosit pentru semnare") : text)
                .foregroundStyle(isProblem ? color : checked ? Color(rgb: 0x2350D8) : Self.ink)
                .font(.system(size: w * 0.033, weight: .medium))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }

    private var statusLine: (String, Color, Bool) {
        if let problem = card.problem { return (problem, Color(rgb: 0xC62828), true) }
        if card.certificate == nil { return (String(localized: "Se citește cardul…"), Color(rgb: 0xD08A00), false) }
        if busy { return (String(localized: "Se semnează…"), Color(rgb: 0x2350D8), false) }
        return (String(localized: "Pregătit pentru semnare"), Color(rgb: 0x1E9E55), false)
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
        let photo = CGRect(x: w * 0.045, y: h * 0.29, width: w * 0.24, height: h * 0.62)
        let frame = Path(roundedRect: photo, cornerRadius: w * 0.02, style: .continuous)
        context.fill(frame, with: .linearGradient(Gradient(colors: [Color(rgb: 0xDDE0E7), Color(rgb: 0xBEC3CE)]),
                                                  startPoint: CGPoint(x: photo.midX, y: photo.minY),
                                                  endPoint: CGPoint(x: photo.midX, y: photo.maxY)))
        var portrait = context
        portrait.clip(to: frame)
        var person = Path(ellipseIn: CGRect(x: photo.midX - photo.width * 0.21, y: photo.minY + photo.height * 0.2,
                                            width: photo.width * 0.42, height: photo.width * 0.48))
        person.addEllipse(in: CGRect(x: photo.minX + photo.width * 0.06, y: photo.minY + photo.height * 0.66,
                                     width: photo.width * 0.88, height: photo.height * 0.62))
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
        guard let cert = card.certificate else { return String(localized: "Card în \(card.reader), se citește") }
        let until = cert.notAfter.map { $0.formatted(date: .abbreviated, time: .omitted) } ?? "—"
        if let problem = card.problem { return "\(cert.holder), \(problem)" }
        return String(localized: "\(cert.holder), card de identitate, valabil până la \(until)")
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
                        p.move(to: CGPoint(x: w * 0.38, y: 0)); p.addLine(to: CGPoint(x: w * 0.38, y: h))
                        p.move(to: CGPoint(x: w * 0.62, y: 0)); p.addLine(to: CGPoint(x: w * 0.62, y: h))
                        p.move(to: CGPoint(x: 0, y: h * 0.5)); p.addLine(to: CGPoint(x: w * 0.38, y: h * 0.5))
                        p.move(to: CGPoint(x: w * 0.62, y: h * 0.5)); p.addLine(to: CGPoint(x: w, y: h * 0.5))
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
                Button("Cum conectez cititorul?") { showGuide = true }
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
        .accessibilityElement(children: .combine)
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
