import Foundation

/// The delayed preview never reads hardware or the system keyring.
struct DemoCardDataProvider: CardDataProviding {
    let demo: DemoMode

    func read(reader: String, completion: @escaping (CardReadResult) -> Void) {
        after(milliseconds: 700) {
            let certificate = demo.certificates[reader]
            completion(CardReadResult(certificate: certificate,
                                      problem: certificate == nil ? demo.failure : nil))
        }
    }
}
