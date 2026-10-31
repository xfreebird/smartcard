import CAdwaita
import Foundation

/// Cairo + Pango drawing for the card wallet.
///
/// * The card face (docs/10 §0.2b, UX-09): a stylized illustration of the Moldovan identity card: pastel paper,
///   guilloche waves and a rosette, bilingual headings, a NEUTRAL shield outline (never the coat of arms), the gold
///   chip, a grey portrait frame with a silhouette, the labelled fields and a status strip. It shows only data
///   from the signing certificate: no photo, no document number, no MRZ, no IDNP. Fixed colors in light and dark
///   (it depicts a physical object), all sizes relative to the width W.
/// * The placeholder cards (docs/10 §0.2): dashed "insert the card", reader + cable, red-tinted error. These
///   follow the theme.
enum CardArt {
    /// Golden-ratio illustration; not a scale reproduction of an identity document.
    static let aspect = (1 + sqrt(5.0)) / 2
    static let large = (width: Int32(340), height: Int32(210))
    static let compact = (width: Int32(260), height: Int32(161))
    /// Placeholder corner radius at the large size (docs/10 §2 "card 14"); the face uses 0.045 W.
    static let radius = 14.0

    struct RGB {
        var r, g, b: Double
        static let white = RGB(r: 1, g: 1, b: 1)

        init(r: Double, g: Double, b: Double) {
            self.r = r
            self.g = g
            self.b = b
        }

        init(_ hex: UInt32) {
            r = Double((hex >> 16) & 0xFF) / 255
            g = Double((hex >> 8) & 0xFF) / 255
            b = Double(hex & 0xFF) / 255
        }

        /// The same color with its hue rotated by `degrees` (HSL).
        func rotated(_ degrees: Double) -> RGB {
            let maxC = max(r, g, b), minC = min(r, g, b)
            let l = (maxC + minC) / 2
            guard maxC != minC else { return self }
            let d = maxC - minC
            let s = l > 0.5 ? d / (2 - maxC - minC) : d / (maxC + minC)
            var h: Double
            switch maxC {
            case r: h = (g - b) / d + (g < b ? 6 : 0)
            case g: h = (b - r) / d + 2
            default: h = (r - g) / d + 4
            }
            h *= 60
            return CardArt.hsl(h + degrees, s, l)
        }
    }

    /// Per-card guilloche hue rotation, ±20° from the first byte of the certificate SHA-1 (before the certificate
    /// is read, a stable value from the reader name) so two cards differ at a glance.
    static func hueShift(sha1Hex: String?, fallback: String) -> Double {
        let byte: Int
        if let sha1Hex, sha1Hex.count >= 2, let value = Int(sha1Hex.prefix(2), radix: 16) {
            byte = value
        } else {
            byte = fallback.utf8.reduce(0) { ($0 &* 31 &+ Int($1)) & 0xFF }
        }
        return Double(byte) / 255 * 40 - 20
    }

    static func hsl(_ h: Double, _ s: Double, _ l: Double) -> RGB {
        let hue = (h.truncatingRemainder(dividingBy: 360) + 360).truncatingRemainder(dividingBy: 360) / 360
        func channel(_ t0: Double) -> Double {
            let q = l < 0.5 ? l * (1 + s) : l + s - l * s
            let p = 2 * l - q
            var t = t0
            if t < 0 { t += 1 }
            if t > 1 { t -= 1 }
            if t < 1 / 6 { return p + (q - p) * 6 * t }
            if t < 1 / 2 { return q }
            if t < 2 / 3 { return p + (q - p) * (2 / 3 - t) * 6 }
            return p
        }
        return RGB(r: channel(hue + 1 / 3), g: channel(hue), b: channel(hue - 1 / 3))
    }

    // MARK: - ID card face (docs/10 §0.2b)

    /// What the face shows. Values are nil while the card is read (placeholder bars are drawn instead).
    struct Face: Equatable {
        enum State: Equatable { case ready, reading, busy, problem(String) }
        var surname: String?
        var givenNames: String?
        var validUntil: Date?
        var issuer: String?
        var state: State
        var reader: String
        var hueShift: Double
        /// Reader caption under the status line (large sizes only).
        var showsReader: Bool
        /// More than one card: the disclosure button sits at the right edge (centre 0.935 W, 0.50 H), so field
        /// values stop at 0.88 W.
        var reservesDisclosure: Bool
        /// The selected card in the expanded list: the status strip reads "✓ Folosit pentru semnare" in brand blue.
        var chosen = false
    }

    // fixed palette (§0.2b)
    private static let navy = RGB(0x283A8C)
    private static let burgundy = RGB(0x9E2A3F)
    private static let labelGrey = RGB(0x5A6070)
    private static let valueInk = RGB(0x1E2230)
    private static let bar = RGB(0xC9CDD6)
    private static let statusGreen = RGB(0x1F8A4C)
    private static let statusAmber = RGB(0xB7791F)
    private static let statusBlue = RGB(0x2350D8)
    private static let statusRed = RGB(0xC62828)

    /// `font`: the widget's font description (system font family; sizes are set here, relative to W).
    static func drawIDCard(_ cr: OpaquePointer, width W: Double, height H: Double, face: Face, font: OpaquePointer?) {
        let corner = 0.045 * W
        roundedRect(cr, 0, 0, W, H, corner)
        cairo_save(cr)
        cairo_clip(cr)

        // paper
        let paper = cairo_pattern_create_linear(0, 0, W, H)
        for (offset, color) in [(0.0, RGB(0xF4EAF0)), (0.5, RGB(0xECEFF7)), (1.0, RGB(0xF6F0E1))] {
            cairo_pattern_add_color_stop_rgb(paper, offset, color.r, color.g, color.b)
        }
        cairo_set_source(cr, paper)
        cairo_paint(cr)
        cairo_pattern_destroy(paper)

        // guilloche: 12 sine waves, alternating rose / blue, then the rosette (hue rotated per card)
        let rose = RGB(0xC6A3BC).rotated(face.hueShift)
        let blue = RGB(0xA7B6DA).rotated(face.hueShift)
        for i in 0..<12 {
            let base = H * (Double(i) + 0.5) / 12
            let phase = Double(i) * 0.35
            let color = i.isMultiple(of: 2) ? rose : blue
            cairo_set_source_rgba(cr, color.r, color.g, color.b, 0.35)
            cairo_set_line_width(cr, i.isMultiple(of: 2) ? 0.8 : 0.5)
            var x = 0.0
            cairo_move_to(cr, 0, base + sin(phase) * 0.04 * H)
            while x <= W {
                x += 2
                cairo_line_to(cr, x, base + sin(2 * .pi * x / (0.55 * W) + phase) * 0.04 * H)
            }
            cairo_stroke(cr)
        }
        let gold = RGB(0xC9B48A).rotated(face.hueShift)
        cairo_set_source_rgba(cr, gold.r, gold.g, gold.b, 0.25)
        cairo_set_line_width(cr, 0.8)
        for k in 0..<8 {
            cairo_save(cr)
            cairo_translate(cr, 0.78 * W, 0.62 * H)
            cairo_rotate(cr, Double(k) * .pi / 8)
            cairo_scale(cr, 1, 0.32)
            cairo_new_sub_path(cr)
            cairo_arc(cr, 0, 0, 0.22 * W, 0, 2 * .pi)
            cairo_restore(cr)
            cairo_stroke(cr)
        }
        cairo_restore(cr)

        // hairline so the card reads on dark windows (the shadow is CSS)
        roundedRect(cr, 0.5, 0.5, W - 1, H - 1, corner - 0.5)
        cairo_set_source_rgba(cr, 0, 0, 0, 0.18)
        cairo_set_line_width(cr, 1)
        cairo_stroke(cr)

        drawHeader(cr, W: W, H: H, font: font)
        drawPortrait(cr, W: W, H: H)
        drawFields(cr, W: W, H: H, face: face, font: font)
        drawStatus(cr, W: W, H: H, face: face, font: font)
    }

    /// "REPUBLICA MOLDOVA / REPUBLIC OF MOLDOVA" · neutral shield · "CARTE DE IDENTITATE / IDENTITY CARD" · chip.
    private static func drawHeader(_ cr: OpaquePointer, W: Double, H: Double, font: OpaquePointer?) {
        let chipW = 0.10 * W, chipH = 0.075 * W
        let chipX = W * 0.85
        drawChip(cr, x: chipX, y: (H - chipH) / 2, width: chipW, height: chipH)

        // fit both headings and the shield between the left margin and the chip (system fonts differ in width)
        let left = (big: "REPUBLICA MOLDOVA", small: "REPUBLIC OF MOLDOVA")
        let right = (big: "CARTE DE IDENTITATE", small: "IDENTITY CARD")
        var big = 0.036 * W, small = 0.026 * W
        let spacing = 0.06   // letter spacing of the first line, in em
        func blockWidth(_ texts: (big: String, small: String), _ big: Double, _ small: Double) -> Double {
            max(measure(cr, texts.big, size: big, weight: PANGO_WEIGHT_BOLD, letterSpacing: spacing * big, font: font).w,
                measure(cr, texts.small, size: small, weight: PANGO_WEIGHT_NORMAL, font: font).w)
        }
        let emblemH = 0.07 * W, emblemW = emblemH * 0.82, gap = 0.022 * W
        let available = W * 0.91
        // text width is not linear in the size (hinting): shrink, re-measure, until both headings fit
        for _ in 0..<6 {
            let natural = blockWidth(left, big, small) + blockWidth(right, big, small) + emblemW + 2 * gap
            guard natural > available else { break }
            let factor = max(0.6, available / natural * 0.98)
            big *= factor
            small *= factor
        }

        var x = 0.045 * W
        let y = 0.06 * H
        let leftWidth = heading(cr, left, x: x, y: y, big: big, small: small, spacing: spacing, color: navy, font: font)
        x += leftWidth + gap
        let blockH = big * 1.25 + small * 1.25 + 4
        drawShield(cr, x: x, y: y + (blockH - emblemH) / 2, width: emblemW, height: emblemH)
        x += emblemW + gap
        _ = heading(cr, right, x: x, y: y, big: big, small: small, spacing: spacing, color: burgundy, font: font)
    }

    /// Two heading lines, each with a 1 px rule under it; returns the block width.
    private static func heading(_ cr: OpaquePointer, _ texts: (big: String, small: String), x: Double, y: Double,
                                big: Double, small: Double, spacing: Double, color: RGB, font: OpaquePointer?) -> Double {
        let first = text(cr, texts.big, x: x, y: y, size: big, weight: PANGO_WEIGHT_BOLD, color: color,
                         letterSpacing: spacing * big, font: font)
        let secondY = y + first.h + 2
        let second = text(cr, texts.small, x: x, y: secondY, size: small, weight: PANGO_WEIGHT_NORMAL, color: color, font: font)
        let width = max(first.w, second.w)
        cairo_set_source_rgba(cr, color.r, color.g, color.b, 0.8)
        cairo_set_line_width(cr, 1)
        for ruleY in [y + first.h + 0.5, secondY + second.h + 0.5] {
            cairo_move_to(cr, x, ruleY)
            cairo_line_to(cr, x + width, ruleY)
        }
        cairo_stroke(cr)
        return width
    }

    /// A plain heater shield outline: bronze stroke, pale fill, an inner line. No charges, no state symbols.
    private static func drawShield(_ cr: OpaquePointer, x: Double, y: Double, width w: Double, height h: Double) {
        func path(_ inset: Double) {
            let l = x + inset, r = x + w - inset, t = y + inset, b = y + h - inset
            cairo_new_path(cr)
            cairo_move_to(cr, l, t)
            cairo_line_to(cr, r, t)
            cairo_line_to(cr, r, t + (b - t) * 0.45)
            cairo_curve_to(cr, r, t + (b - t) * 0.78, (l + r) / 2 + (r - l) * 0.18, b - (b - t) * 0.06, (l + r) / 2, b)
            cairo_curve_to(cr, (l + r) / 2 - (r - l) * 0.18, b - (b - t) * 0.06, l, t + (b - t) * 0.78, l, t + (b - t) * 0.45)
            cairo_close_path(cr)
        }
        let fill = RGB(0xE9D9B4), stroke = RGB(0x8C6A3A)
        path(0)
        cairo_set_source_rgba(cr, fill.r, fill.g, fill.b, 0.6)
        cairo_fill_preserve(cr)
        cairo_set_source_rgb(cr, stroke.r, stroke.g, stroke.b)
        cairo_set_line_width(cr, max(1, w * 0.06))
        cairo_stroke(cr)
        path(w * 0.16)
        cairo_set_source_rgba(cr, stroke.r, stroke.g, stroke.b, 0.55)
        cairo_set_line_width(cr, max(0.6, w * 0.03))
        cairo_stroke(cr)
    }

    /// Grey frame with a neutral head-and-shoulders silhouette (never a photo).
    private static func drawPortrait(_ cr: OpaquePointer, W: Double, H: Double) {
        let x = 0.045 * W, y = 0.30 * H, w = 0.20 * W, h = 0.20 * W * 5 / 3
        roundedRect(cr, x, y, w, h, 0.02 * W)
        let frame = cairo_pattern_create_linear(0, y, 0, y + h)
        let top = RGB(0xD9DCE3), bottom = RGB(0xBFC4CF)
        cairo_pattern_add_color_stop_rgb(frame, 0, top.r, top.g, top.b)
        cairo_pattern_add_color_stop_rgb(frame, 1, bottom.r, bottom.g, bottom.b)
        cairo_set_source(cr, frame)
        cairo_fill_preserve(cr)
        cairo_pattern_destroy(frame)
        cairo_save(cr)
        cairo_clip(cr)
        let ink = RGB(0x8E95A3)
        cairo_set_source_rgb(cr, ink.r, ink.g, ink.b)
        let cx = x + w / 2
        // A compact bust, centered inside the 3:5 portrait frame. The shoulders are a shallow
        // arc rather than long vertical torso sides; all figure dimensions use the frame width.
        let headY = y + h * 0.34
        cairo_new_sub_path(cr)
        cairo_arc(cr, cx, headY, w * 0.23, 0, 2 * .pi)
        cairo_fill(cr)
        let shoulderTop = headY + w * 0.31
        let shoulderBase = shoulderTop + w * 0.36
        cairo_new_path(cr)
        cairo_move_to(cr, cx - w * 0.46, shoulderBase)
        cairo_curve_to(cr, cx - w * 0.44, shoulderTop + w * 0.11,
                       cx - w * 0.23, shoulderTop, cx, shoulderTop)
        cairo_curve_to(cr, cx + w * 0.23, shoulderTop,
                       cx + w * 0.44, shoulderTop + w * 0.11, cx + w * 0.46, shoulderBase)
        cairo_close_path(cr)
        cairo_fill(cr)
        cairo_restore(cr)
    }

    /// Numele/Surname, Prenumele/Given name(s), Valabil până la/Valid until + Emitent/Issuer.
    private static func drawFields(_ cr: OpaquePointer, W: Double, H: Double, face: Face, font: OpaquePointer?) {
        let x = 0.32 * W, column2 = 0.64 * W, right = 0.83 * W
        let date = face.validUntil.map(Format.cardDate)
        let rows: [(y: Double, label: String, value: String?, x: Double, maxX: Double, bar: Double)] = [
            (0.30, L10n.text(.ui_surname), face.surname, x, right, 0.34),
            (0.47, L10n.text(.ui_given_names), face.givenNames, x, right, 0.26),
            (0.64, L10n.text(.ui_valid_until_2), date, x, column2 - 0.02 * W, 0.18),
            (0.64, L10n.text(.ui_issuer), face.issuer, column2, right, 0.16),
        ]
        for row in rows {
            let y = row.y * H
            let label = text(cr, row.label, x: row.x, y: y, size: 0.024 * W, weight: PANGO_WEIGHT_NORMAL,
                             color: labelGrey, maxWidth: row.maxX - row.x, font: font)
            let valueY = y + label.h + 0.004 * W
            if let value = row.value, !value.isEmpty {
                // shrink a long value (down to 70 %) before ellipsizing it
                let text = value.uppercased(), maxWidth = row.maxX - row.x
                var size = 0.046 * W
                let natural = measure(cr, text, size: size, weight: PANGO_WEIGHT_SEMIBOLD, font: font).w
                if natural > maxWidth { size *= max(0.7, maxWidth / natural * 0.98) }
                let shift = (0.046 * W - size) * 0.8   // keep the baseline roughly in place
                _ = self.text(cr, text, x: row.x, y: valueY + shift, size: size, weight: PANGO_WEIGHT_SEMIBOLD,
                              color: valueInk, maxWidth: maxWidth, font: font)
            } else {
                // still reading (or unreadable): placeholder bars instead of values
                roundedRect(cr, row.x, valueY + 0.012 * W, row.bar * W, 0.03 * W, 0.015 * W)
                cairo_set_source_rgba(cr, bar.r, bar.g, bar.b, 0.9)
                cairo_fill(cr)
            }
        }
    }

    /// Dot + one line ("Pregătit pentru semnare" / "Se citește cardul…" / the problem), reader as a caption.
    /// The selected card of the expanded list: a check instead of the dot, "Folosit pentru semnare" in brand blue.
    private static func drawStatus(_ cr: OpaquePointer, W: Double, H: Double, face: Face, font: OpaquePointer?) {
        let (color, line): (RGB, String)
        let chosen = face.chosen && face.state == .ready
        switch face.state {
        case .ready where chosen: (color, line) = (statusBlue, L10n.text(.ui_selected_for_signing))
        case .ready: (color, line) = (statusGreen, L10n.text(.ui_ready_to_sign))
        case .reading: (color, line) = (statusAmber, L10n.text(.ui_reading_the_card))
        case .busy: (color, line) = (statusBlue, L10n.text(.ui_signing))
        case .problem(let message): (color, line) = (statusRed, message)
        }
        let x = 0.32 * W, y = 0.80 * H
        let maxX = W - 0.045 * W
        let size = 0.032 * W
        let dot = 0.011 * W
        let lineBox = text(cr, line, x: x + dot * 2 + 0.012 * W, y: y, size: size, weight: PANGO_WEIGHT_SEMIBOLD,
                           color: color, maxWidth: maxX - x - dot * 2 - 0.012 * W, font: font)
        cairo_set_source_rgb(cr, color.r, color.g, color.b)
        let cy = y + lineBox.h / 2
        if chosen {
            // check mark in the dot's place
            cairo_set_line_width(cr, max(1.4, 0.0065 * W))
            cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
            cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND)
            cairo_move_to(cr, x + dot * 0.15, cy + dot * 0.05)
            cairo_line_to(cr, x + dot * 0.8, cy + dot * 0.75)
            cairo_line_to(cr, x + dot * 2.1, cy - dot * 0.85)
            cairo_stroke(cr)
            cairo_set_line_cap(cr, CAIRO_LINE_CAP_BUTT)
            cairo_set_line_join(cr, CAIRO_LINE_JOIN_MITER)
        } else {
            cairo_new_sub_path(cr)
            cairo_arc(cr, x + dot, cy, dot, 0, 2 * .pi)
            cairo_fill(cr)
        }
        if face.showsReader {
            _ = text(cr, face.reader, x: x, y: y + lineBox.h + 0.004 * W, size: 0.024 * W, weight: PANGO_WEIGHT_NORMAL,
                     color: labelGrey, maxWidth: maxX - x, font: font)
        }
    }

    // MARK: - Text (Pango; the face is one accessible element, its text is described by the button's label)

    private static func layout(_ cr: OpaquePointer, _ string: String, size: Double, weight: PangoWeight,
                               letterSpacing: Double, maxWidth: Double?, font: OpaquePointer?) -> OpaquePointer? {
        guard let layout = pango_cairo_create_layout(cr) else { return nil }
        let description = font.map { pango_font_description_copy($0) } ?? pango_font_description_from_string("Sans")
        pango_font_description_set_absolute_size(description, size * 1024)   // PANGO_SCALE
        pango_font_description_set_weight(description, weight)
        pango_layout_set_font_description(layout, description)
        pango_font_description_free(description)
        if letterSpacing > 0, let attributes = pango_attr_list_new() {
            pango_attr_list_insert(attributes, pango_attr_letter_spacing_new(Int32(letterSpacing * 1024)))
            pango_layout_set_attributes(layout, attributes)
            pango_attr_list_unref(attributes)
        }
        if let maxWidth {
            pango_layout_set_width(layout, Int32(max(1, maxWidth) * 1024))
            pango_layout_set_ellipsize(layout, PANGO_ELLIPSIZE_END)
        }
        pango_layout_set_text(layout, string, -1)
        return layout
    }

    private static func measure(_ cr: OpaquePointer, _ string: String, size: Double, weight: PangoWeight,
                                letterSpacing: Double = 0, font: OpaquePointer?) -> (w: Double, h: Double) {
        guard let layout = layout(cr, string, size: size, weight: weight, letterSpacing: letterSpacing,
                                  maxWidth: nil, font: font) else { return (0, 0) }
        defer { g_object_unref(UnsafeMutableRawPointer(layout)) }
        var w: Int32 = 0, h: Int32 = 0
        pango_layout_get_pixel_size(layout, &w, &h)
        return (Double(w), Double(h))
    }

    @discardableResult
    private static func text(_ cr: OpaquePointer, _ string: String, x: Double, y: Double, size: Double,
                             weight: PangoWeight, color: RGB, maxWidth: Double? = nil, letterSpacing: Double = 0,
                             font: OpaquePointer?) -> (w: Double, h: Double) {
        guard let layout = layout(cr, string, size: size, weight: weight, letterSpacing: letterSpacing,
                                  maxWidth: maxWidth, font: font) else { return (0, 0) }
        defer { g_object_unref(UnsafeMutableRawPointer(layout)) }
        var w: Int32 = 0, h: Int32 = 0
        pango_layout_get_pixel_size(layout, &w, &h)
        cairo_set_source_rgb(cr, color.r, color.g, color.b)
        cairo_move_to(cr, x, y)
        pango_cairo_show_layout(cr, layout)
        return (Double(w), Double(h))
    }

    /// Gold contact plate (accent `#F5B700`, decoration only).
    static func drawChip(_ cr: OpaquePointer, x: Double, y: Double, width w: Double, height h: Double) {
        roundedRect(cr, x, y, w, h, w * 0.14)
        let gold = cairo_pattern_create_linear(x, y, x + w, y + h)
        cairo_pattern_add_color_stop_rgb(gold, 0, 0.98, 0.86, 0.48)
        cairo_pattern_add_color_stop_rgb(gold, 0.5, 0.96, 0.72, 0.0)
        cairo_pattern_add_color_stop_rgb(gold, 1, 0.99, 0.82, 0.36)
        cairo_set_source(cr, gold)
        cairo_fill_preserve(cr)
        cairo_pattern_destroy(gold)
        cairo_set_source_rgba(cr, 0.45, 0.30, 0.0, 0.55)
        cairo_set_line_width(cr, 1)
        cairo_stroke(cr)

        // Eight contact regions: three on each side and two in the center.
        cairo_save(cr)
        roundedRect(cr, x, y, w, h, w * 0.14)
        cairo_clip(cr)
        cairo_set_source_rgba(cr, 0.38, 0.25, 0.02, 0.72)
        cairo_set_line_width(cr, max(0.7, w * 0.024))
        for column in [0.32, 0.68] {
            cairo_move_to(cr, x + w * column, y)
            cairo_line_to(cr, x + w * column, y + h)
        }
        for row in [1.0 / 3.0, 2.0 / 3.0] {
            cairo_move_to(cr, x, y + h * row)
            cairo_line_to(cr, x + w * 0.32, y + h * row)
            cairo_move_to(cr, x + w * 0.68, y + h * row)
            cairo_line_to(cr, x + w, y + h * row)
        }
        cairo_move_to(cr, x + w * 0.32, y + h * 0.5)
        cairo_line_to(cr, x + w * 0.68, y + h * 0.5)
        cairo_stroke(cr)
        cairo_restore(cr)

    }

    // MARK: - Placeholders (empty states are cards too)

    enum Placeholder: Equatable {
        case insertCard   // reader connected, no card: dashed outline + card going into a slot
        case noReader     // nothing connected: reader + USB cable
        case error        // red-tinted card
    }

    /// `fg`: the widget's text color (theme-aware); `danger`: docs/10 `danger` token for the current theme.
    static func drawPlaceholder(_ cr: OpaquePointer, _ kind: Placeholder, width: Double, height: Double,
                                fg: RGB, danger: RGB, glyphCenterY: Double, glyphScale: Double = 1) {
        let r = radius * width / Double(large.width)
        let unit = width / Double(large.width) * glyphScale
        switch kind {
        case .insertCard, .noReader:
            roundedRect(cr, 1, 1, width - 2, height - 2, r)
            cairo_set_source_rgba(cr, fg.r, fg.g, fg.b, 0.04)
            cairo_fill_preserve(cr)
            var dashes: [Double] = [8 * r / radius, 6 * r / radius]
            cairo_set_dash(cr, &dashes, 2, 0)
            cairo_set_line_width(cr, 2)
            cairo_set_source_rgba(cr, fg.r, fg.g, fg.b, 0.32)
            cairo_stroke(cr)
            cairo_set_dash(cr, nil, 0, 0)
            if kind == .insertCard {
                drawInsertGlyph(cr, cx: width / 2, cy: glyphCenterY, unit: unit, fg: fg)
            } else {
                drawReaderGlyph(cr, cx: width / 2, cy: glyphCenterY, unit: unit, fg: fg)
            }
        case .error:
            roundedRect(cr, 0.75, 0.75, width - 1.5, height - 1.5, r)
            cairo_set_source_rgba(cr, danger.r, danger.g, danger.b, 0.10)
            cairo_fill_preserve(cr)
            cairo_set_source_rgba(cr, danger.r, danger.g, danger.b, 0.55)
            cairo_set_line_width(cr, 1.5)
            cairo_stroke(cr)
            drawWarningGlyph(cr, cx: width / 2, cy: glyphCenterY, unit: unit, color: danger)
        }
    }

    /// A small card above a reader slot with a down arrow: "put the card in".
    private static func drawInsertGlyph(_ cr: OpaquePointer, cx: Double, cy: Double, unit: Double, fg: RGB) {
        let w = 58 * unit, h = w / aspect
        let x = cx - w / 2, y = cy - h / 2 - 8 * unit
        cairo_set_line_width(cr, 2)
        cairo_set_source_rgba(cr, fg.r, fg.g, fg.b, 0.55)
        roundedRect(cr, x, y, w, h, 4 * unit)
        cairo_stroke(cr)
        roundedRect(cr, x + w * 0.12, y + h * 0.32, w * 0.2, w * 0.16, 2 * unit)   // chip
        cairo_stroke(cr)
        // slot
        let slotY = y + h + 10 * unit
        cairo_set_line_width(cr, 3)
        cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
        cairo_move_to(cr, cx - w * 0.7, slotY)
        cairo_line_to(cr, cx + w * 0.7, slotY)
        cairo_stroke(cr)
        // arrow into the slot
        cairo_set_line_width(cr, 2)
        cairo_move_to(cr, cx + w * 0.75, y)
        cairo_line_to(cr, cx + w * 0.75, y + h * 0.75)
        cairo_move_to(cr, cx + w * 0.75 - 5 * unit, y + h * 0.75 - 6 * unit)
        cairo_line_to(cr, cx + w * 0.75, y + h * 0.75)
        cairo_line_to(cr, cx + w * 0.75 + 5 * unit, y + h * 0.75 - 6 * unit)
        cairo_stroke(cr)
        cairo_set_line_cap(cr, CAIRO_LINE_CAP_BUTT)
    }

    /// A pocket reader with its USB cable and plug: "connect the reader".
    private static func drawReaderGlyph(_ cr: OpaquePointer, cx: Double, cy: Double, unit: Double, fg: RGB) {
        let w = 64 * unit, h = 30 * unit
        let x = cx - w / 2 - 16 * unit, y = cy - h / 2
        cairo_set_source_rgba(cr, fg.r, fg.g, fg.b, 0.55)
        cairo_set_line_width(cr, 2)
        roundedRect(cr, x, y, w, h, 6 * unit)
        cairo_stroke(cr)
        // card slot on the reader's face + status LED
        cairo_move_to(cr, x + w * 0.18, y + h * 0.38)
        cairo_line_to(cr, x + w * 0.70, y + h * 0.38)
        cairo_stroke(cr)
        cairo_new_sub_path(cr)
        cairo_arc(cr, x + w * 0.84, y + h * 0.38, 2.5 * unit, 0, 2 * .pi)
        cairo_fill(cr)
        // cable
        cairo_move_to(cr, x + w, y + h / 2)
        cairo_curve_to(cr, x + w + 18 * unit, y + h / 2, x + w + 10 * unit, y - 18 * unit, x + w + 34 * unit, y - 14 * unit)
        cairo_stroke(cr)
        // plug
        let px = x + w + 34 * unit, py = y - 14 * unit
        roundedRect(cr, px, py - 6 * unit, 14 * unit, 12 * unit, 2 * unit)
        cairo_stroke(cr)
        cairo_rectangle(cr, px + 14 * unit, py - 4 * unit, 7 * unit, 8 * unit)
        cairo_stroke(cr)
    }

    private static func drawWarningGlyph(_ cr: OpaquePointer, cx: Double, cy: Double, unit: Double, color: RGB) {
        let s = 34 * unit
        cairo_set_line_join(cr, CAIRO_LINE_JOIN_ROUND)
        cairo_set_line_width(cr, 2.5 * unit)
        cairo_set_source_rgb(cr, color.r, color.g, color.b)
        cairo_move_to(cr, cx, cy - s * 0.5)
        cairo_line_to(cr, cx + s * 0.55, cy + s * 0.45)
        cairo_line_to(cr, cx - s * 0.55, cy + s * 0.45)
        cairo_close_path(cr)
        cairo_stroke(cr)
        cairo_set_line_cap(cr, CAIRO_LINE_CAP_ROUND)
        cairo_move_to(cr, cx, cy - s * 0.15)
        cairo_line_to(cr, cx, cy + s * 0.15)
        cairo_stroke(cr)
        cairo_new_sub_path(cr)
        cairo_arc(cr, cx, cy + s * 0.30, 1.6 * unit, 0, 2 * .pi)
        cairo_fill(cr)
        cairo_set_line_cap(cr, CAIRO_LINE_CAP_BUTT)
        cairo_set_line_join(cr, CAIRO_LINE_JOIN_MITER)
    }

    static func roundedRect(_ cr: OpaquePointer, _ x: Double, _ y: Double, _ w: Double, _ h: Double, _ r: Double) {
        cairo_new_sub_path(cr)
        cairo_arc(cr, x + w - r, y + r, r, -.pi / 2, 0)
        cairo_arc(cr, x + w - r, y + h - r, r, 0, .pi / 2)
        cairo_arc(cr, x + r, y + h - r, r, .pi / 2, .pi)
        cairo_arc(cr, x + r, y + r, r, .pi, 3 * .pi / 2)
        cairo_close_path(cr)
    }
}
