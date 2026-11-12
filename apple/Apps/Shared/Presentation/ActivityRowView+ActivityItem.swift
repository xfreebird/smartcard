extension ActivityRowView {
    init(item: ActivityItem, showsDate: Bool = true) {
        self.init(title: item.title, subtitle: signatureLabels(item.subtitle), date: item.date,
                  succeeded: item.ok, showsDate: showsDate)
    }
}
