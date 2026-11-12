import Foundation

extension CardItemContent {
    init(card: CardSlot, index: Int, count: Int, busy: Bool, selected: Bool, expanded: Bool) {
        let cert = card.certificate
        let state: CardArt.Face.State
        if cert != nil { state = busy ? .busy : .ready }
        else if let problem = card.problem { state = .problem(problem) }
        else { state = .reading }
        face = CardArt.Face(surname: cert?.surname, givenNames: cert?.givenNames,
            validUntil: cert?.notAfter.map(Format.cardDate), issuer: cert?.issuerName,
            state: state, reader: card.reader,
            hueShift: CardArt.hueShift(sha1Hex: cert?.sha1Hex, fallback: card.reader),
            showsReader: true, reservesDisclosure: false, chosen: selected && expanded)
        self.selected = selected
        self.expanded = expanded
        disclosureLabel = localized(.linux_choose_card_count, String(count))
        disclosureTooltip = expanded ? L10n.text(.ui_close_list) : disclosureLabel
        let holder = cert?.holder
        if expanded {
            label = holder.map { localized(.linux_sign_with_holder, $0) } ?? localized(.linux_card_in_reader, card.reader)
            tooltip = selected ? L10n.text(.ui_selected_for_signing) : (holder.map { localized(.linux_sign_with_holder, $0) } ?? "")
            return
        }
        var parts: [String]
        switch state {
        case .ready, .busy:
            parts = [localized(.linux_identity_holder, holder ?? "—")]
            if let until = cert?.notAfter { parts.append(localized(.linux_valid_until, Format.monthYear(until))) }
            parts.append(state == .busy ? L10n.text(.ui_signing_2) : L10n.text(.ui_ready_to_sign_2))
        case .reading:
            parts = [localized(.linux_identity_in_reader, card.reader), L10n.text(.ui_reading)]
        case .problem(let problem):
            parts = [localized(.linux_identity_in_reader, card.reader), problem, L10n.text(.ui_remove_and_reinsert_the_card)]
        }
        if count > 1 { parts.append(localized(.linux_card_position, String(index + 1), String(count))) }
        label = parts.joined(separator: ", ")
        tooltip = count > 1 ? L10n.text(.ui_card_details_switches_cards) : L10n.text(.linux_card_details)
    }
}
