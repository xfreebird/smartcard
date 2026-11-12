extension EmptyCardContent {
    init(status: ReaderStatus) {
        let symbol: String
        let isError: Bool
        let isReading: Bool
        switch status {
        case .noReader: (symbol, isError, isReading) = ("cable.connector", false, false)
        case .reading: (symbol, isError, isReading) = ("creditcard.viewfinder", false, true)
        case .error, .unavailable: (symbol, isError, isReading) = ("exclamationmark.triangle", true, false)
        default: (symbol, isError, isReading) = ("creditcard", false, false)
        }
        var actionTitle: String?
        #if os(iOS)
        if case .noReader = status { actionTitle = L10n.text(.ui_how_do_i_connect_the_reader) }
        #endif
        self.init(title: status.title, subtitle: status.subtitle, symbol: symbol,
                  isError: isError, isReading: isReading, actionTitle: actionTitle)
    }
}
