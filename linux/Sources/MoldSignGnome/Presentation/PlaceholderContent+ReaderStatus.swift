extension PlaceholderContent {
    init(status: ReaderStatus) {
        switch status {
        case .error(let message, let recovery):
            kind = .error
            title = message
            caption = recovery
        case .empty(let reader):
            kind = .insertCard
            title = L10n.text(.linux_insert_card)
            caption = reader
        default:
            kind = .noReader
            title = L10n.text(.ui_connect_the_reader)
            caption = L10n.text(.ui_usb_smart_card_reader_e_g_bit4id_minilector)
        }
    }
}
