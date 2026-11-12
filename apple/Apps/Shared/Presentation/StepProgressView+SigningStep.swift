import MoldSignKit

extension StepProgressView {
    init(current: SigningService.Step) {
        let order: [SigningService.Step] = [.connecting, .authenticating, .readingCertificate, .verifyingPIN,
                                            .signing, .timestamping, .writing, .done]
        let steps: [(SigningService.Step, String)] = [
            (.authenticating, L10n.text(.ui_card)), (.verifyingPIN, L10n.text(.ui_pin)),
            (.signing, L10n.text(.ui_signature)), (.timestamping, L10n.text(.ui_timestamp)),
            (.writing, L10n.text(.ui_saving)),
        ]
        let position = order.firstIndex(of: current) ?? 0
        let completed = steps.filter { current == .done || position > (order.firstIndex(of: $0.0) ?? position) }.count
        let active = steps.first { $0.0 == current }
        let label = active?.1 ?? L10n.text(current == .done ? .ui_done : .ui_card)
        self.init(label: label, completed: completed, total: steps.count)
    }
}
