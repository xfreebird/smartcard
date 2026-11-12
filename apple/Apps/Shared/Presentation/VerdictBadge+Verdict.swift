extension VerdictBadge {
    init(verdict: Verdict) {
        self.init(title: verdict.title, subtitle: verdict.subtitle, symbol: verdict.symbol, tint: verdict.tint)
    }
}
