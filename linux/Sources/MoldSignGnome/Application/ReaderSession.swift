import Dispatch
import Foundation
import MoldSignKit

/// Owns card discovery, insertion generations and selection. It ignores stale certificate reads.
final class ReaderSession {
    var status: ReaderStatus = .noReader
    var cards: [CardSlot] = []
    private(set) var selectedReaderName: String?
    var selectedCard: CardSlot? { cards.first { $0.reader == selectedReaderName } ?? cards.first }
    var isSigning: Bool { isBusy?() ?? false }
    var isBusy: (() -> Bool)?
    var onChange: (() -> Void)?
    var onInsertion: (() -> Void)?
    var onSelection: (() -> Void)?
    var showOnCardInsertion: (() -> Bool)?
    private var lastSnapshot = ReaderSnapshot()
    private var hasReceivedSnapshot = false
    private let service: SigningService
    private let vault: any PINStoring
    private let monitor: any CardMonitoring
    private let transportFactory: ((String?) throws -> CardTransport)?
    private let selectedReader = SelectedReader()
    private let cardQueue = DispatchQueue(label: "md.moldsign.reader")
    #if MOLDSIGN_DEMO
    private let demo = DemoMode.current
    #endif

    init(service: SigningService, vault: any PINStoring, monitor: any CardMonitoring,
         transportFactory: ((String?) throws -> CardTransport)?) {
        self.service = service; self.vault = vault; self.monitor = monitor; self.transportFactory = transportFactory
    }

    func start() {
        let selected = selectedReader
        service.transportFactory = transportFactory ?? { reader in try CardTransports.connect(reader: reader ?? selected.name) }
        monitor.onChange = { [weak self] in self?.apply($0) }
        monitor.start(interval: .seconds(1))
    }

    func stop() { monitor.stop() }
    func refreshSnapshot() { apply(lastSnapshot) }
    private func changed() { onChange?() }

    // MARK: - Reader state (LNX-08)

    func apply(_ snapshot: ReaderSnapshot) {
        lastSnapshot = snapshot
        var next: [CardSlot] = []
        var toRead: [CardSlot] = []
        for slot in snapshot.slots where slot.state == .card {
            if let known = cards.first(where: { $0.reader == slot.name }), known.generation == slot.generation {
                next.append(known)
            } else {
                // new card, or the same reader got a card again (removed + reinserted / swapped): forget the old one
                let fresh = CardSlot(reader: slot.name, generation: slot.generation)
                next.append(fresh)
                toRead.append(fresh)
            }
        }
        let inserted = hasReceivedSnapshot && !toRead.isEmpty
        hasReceivedSnapshot = true
        cards = next
        if selectedReaderName.map({ name in !next.contains { $0.reader == name } }) ?? true {
            selectedReaderName = next.first?.reader
        }
        selectedReader.name = selectedCard?.reader
        recomputeStatus()
        for card in toRead { readCertificate(of: card) }
        if inserted && (showOnCardInsertion?() ?? false) { onInsertion?() }
    }

    /// PIN-less certificate read so the UI can greet the holder (MAC-02 equivalent). Ignored if the card changed meanwhile.
    func readCertificate(of card: CardSlot) {
        #if MOLDSIGN_DEMO
        if let demo {
            // a short "reading" phase, like a real PIN-less read
            after(milliseconds: 700) { [weak self] in
                guard let self,
                      let index = self.cards.firstIndex(where: { $0.reader == card.reader && $0.generation == card.generation })
                else { return }
                self.cards[index].certificate = demo.certificates[card.reader]
                self.cards[index].problem = demo.certificates[card.reader] == nil ? demo.failure : nil
                self.recomputeStatus()
            }
            return
        }
        #endif
        let service = self.service
        let vault = self.vault
        let reader = card.reader
        cardQueue.async { [weak self] in
            let result = Result { try service.readCertificate(reader: reader) }
            let stored = (try? result.get()).map { vault.hasPIN(certID: $0.sha1Hex) } ?? false
            onMain { [weak self] in
                guard let self,
                      let index = self.cards.firstIndex(where: { $0.reader == reader && $0.generation == card.generation })
                else { return }
                switch result {
                case .success(let cert):
                    self.cards[index].certificate = cert
                    self.cards[index].problem = nil
                    self.cards[index].hasStoredPIN = stored
                case .failure(let error):
                    self.cards[index].problem = UserFacingError.describe(error).message
                }
                self.recomputeStatus()
            }
        }
    }

    /// "Recitește cardul": forget what we know about the inserted cards and read them again.
    func rereadCards() {
        guard !isSigning else { return }
        for index in cards.indices {
            cards[index].certificate = nil
            cards[index].problem = nil
        }
        recomputeStatus()
        for card in cards { readCertificate(of: card) }
    }

    /// "Recitește cardul" on one card of the wallet (its context menu).
    func rereadCard(reader: String) {
        guard !isSigning, let index = cards.firstIndex(where: { $0.reader == reader }) else { return }
        cards[index].certificate = nil
        cards[index].problem = nil
        recomputeStatus()
        readCertificate(of: cards[index])
    }

    /// "Reîncearcă" / the header's re-read button: re-read the inserted cards, or re-poll the readers when there are none.
    func retryCard() {
        #if MOLDSIGN_DEMO
        if let demo, cards.isEmpty { return apply(demo.snapshot) }
        #endif
        if cards.isEmpty { monitor.refresh() } else { rereadCards() }
    }

    func selectCard(_ reader: String) {
        guard !isSigning, reader != selectedCard?.reader, cards.contains(where: { $0.reader == reader }) else { return }
        selectedReaderName = reader
        selectedReader.name = reader
        onSelection?()
        recomputeStatus()
    }

    func setStoredPIN(_ stored: Bool, certID: String) {
        for index in cards.indices where cards[index].certificate?.sha1Hex == certID {
            cards[index].hasStoredPIN = stored
        }
    }

    func recomputeStatus() {
        guard !isSigning else { return changed() }
        let snapshot = lastSnapshot
        guard let firstReader = snapshot.readers.first else {
            status = snapshot.serviceAvailable
                ? .noReader
                : .error(message: L10n.text(.ui_the_pc_sc_service_is_not_running), recovery: L10n.text(.ui_start_it_sudo_systemctl_enable_now_pcscd_socket))
            return changed()
        }
        guard let card = selectedCard else {
            status = snapshot.muteCard
                ? .error(message: L10n.text(.ui_the_card_does_not_respond), recovery: L10n.text(.ui_remove_and_re_insert_the_card))
                : .empty(reader: firstReader)
            return changed()
        }
        if let cert = card.certificate {
            status = .ready(reader: card.reader, holder: cert.holder, validUntil: cert.notAfter)
        } else if let problem = card.problem {
            status = .error(message: problem, recovery: L10n.text(.ui_remove_and_re_insert_the_card))
        } else {
            status = .reading(reader: card.reader)
        }
        changed()
    }

}
/// Reader of the UI-selected card, read by the transport factory on the card queue.
private final class SelectedReader: @unchecked Sendable {
    private let lock = NSLock()
    private var value: String?
    var name: String? {
        get { lock.lock(); defer { lock.unlock() }; return value }
        set { lock.lock(); value = newValue; lock.unlock() }
    }
}
