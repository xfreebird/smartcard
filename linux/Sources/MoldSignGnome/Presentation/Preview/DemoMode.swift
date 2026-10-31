#if MOLDSIGN_DEMO
import Foundation
import MoldSignKit

/// Debug builds only (`MOLDSIGN_DEMO` is defined for `-c debug` in Package.swift): fake readers and cards
/// for screenshots and layout work, with no PC/SC, card, keyring or bridge I/O.
///
///     MSIGN_DEMO_CARDS=2 .build/debug/moldsign-gnome
///
/// Values: `1`…`4` cards (all readable) · `0` or `empty` (reader, no card) · `noreader` · `error` (one card that
/// does not answer) · `pcscd` (PC/SC service down). Signing and the browser bridge are disabled in this mode.
/// For screenshots: `MSIGN_DEMO_PAGE=sign|verify|activity|card` opens that page, `MSIGN_DEMO_WINDOW=420x760`
/// sets the window size (narrow layouts).
struct DemoMode {
    /// Only automated screenshot fixtures suppress the demo label; interactive demo remains labelled.
    static var screenshotCapture: Bool { ProcessInfo.processInfo.environment["MSIGN_SCREENSHOT_CAPTURE"] == "1" }

    static var page: String? { DemoScenario.current?.page ?? ProcessInfo.processInfo.environment["MSIGN_DEMO_PAGE"] }

    static var windowSize: (width: Int32, height: Int32)? {
        guard let value = ProcessInfo.processInfo.environment["MSIGN_DEMO_WINDOW"] else { return nil }
        let parts = value.lowercased().split(separator: "x").compactMap { Int32($0) }
        return parts.count == 2 ? (parts[0], parts[1]) : nil
    }

    let snapshot: ReaderSnapshot
    /// Reader → certificate (nil: the read fails with `failure`).
    let certificates: [String: SigningService.CertificateSummary]
    let failure = L10n.text(.ui_the_card_does_not_respond)

    static let current: DemoMode? = {
        let environment = ProcessInfo.processInfo.environment
        guard let value = (environment["MSIGN_DEMO_CARDS"] ?? (environment["MSIGN_DEMO_SCENARIO"] != nil ? "1" : nil))?.lowercased(),
              !value.isEmpty else { return nil }
        _ = DemoScenario.current // validate before any possibility of hardware mode
        let demo = DemoMode(value)
        logInfo("demo mode (MSIGN_DEMO_CARDS=\(value)): fake cards, no card or bridge I/O")
        return demo
    }()

    private static let readers = [
        "Bit4id miniLector POCKET EVO 00 00",
        "Bit4id miniLector POCKET EVO 01 00",
        "Alcor Micro AU9540 02 00",
        "Generic Smart Card Reader 03 00",
    ]

    private init(_ value: String) {
        switch value {
        case "noreader":
            snapshot = ReaderSnapshot(slots: [], serviceAvailable: true)
            certificates = [:]
        case "pcscd":
            snapshot = ReaderSnapshot(slots: [], serviceAvailable: false)
            certificates = [:]
        case "0", "empty":
            snapshot = ReaderSnapshot(slots: [.init(name: Self.readers[0], state: .empty, generation: 0)])
            certificates = [:]
        case "error":
            snapshot = ReaderSnapshot(slots: [.init(name: Self.readers[0], state: .card, generation: 1)])
            certificates = [:]
        default:
            let count = min(max(Int(value) ?? 2, 1), Self.readers.count)
            snapshot = ReaderSnapshot(slots: (0..<count).map { .init(name: Self.readers[$0], state: .card, generation: 1) })
            var certificates: [String: SigningService.CertificateSummary] = [:]
            for index in 0..<count {
                if let der = Data(base64Encoded: Self.certificatesBase64[index]) {
                    certificates[Self.readers[index]] = SigningService.CertificateSummary(der: der)
                }
            }
            self.certificates = certificates
        }
    }

    /// Self-made EC test certificates of fictional people: CN = "SURNAME GIVEN" (Moldovan order) with SN / GN,
    /// issuer CN "MDQSign", O = "eSemnBun demo fixture". Not MD PKI certificates; the keys were thrown away.
    private static let certificatesBase64 = [
        // POPESCU ION, until 03/2030
        "MIIB1DCCAXqgAwIBAgICB9EwCgYIKoZIzj0EAwIwPzELMAkGA1UEBhMCTUQxHjAcBgNVBAoMFWVTZW1uQnVuIGRlbW8gZml4dHVyZTEQMA4GA1UEAwwHTURRU2lnbjAeFw0yNjEwMjUxMDQ5MTRaFw0zMDAzMTMxMDQ5MTRaMGMxCzAJBgNVBAYTAk1EMR4wHAYDVQQKDBVlU2VtbkJ1biBkZW1vIGZpeHR1cmUxEDAOBgNVBAQMB1BPUEVTQ1UxDDAKBgNVBCoMA0lPTjEUMBIGA1UEAwwLUE9QRVNDVSBJT04wWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAARb95LczMX4VaPY3d+hhZmLYpuWORDu3mFzLjrmeeqb8nQqxP498gokDzm21mXq58xudDr5nJwoOMtzLxCRamJAo0IwQDAdBgNVHQ4EFgQUNRE15d77e4WIg/H7zZMr5yfvngowHwYDVR0jBBgwFoAUF66O4wWUqCdodQ2sroinBQQSJ9owCgYIKoZIzj0EAwIDSAAwRQIgZUyF9mIHYQ5IEDogdzGGGvjoiTsmsrtlzJGB568K1DgCIQDLV3tNEMy+mdOrgUrTL51xChH0u1n9Uq9Vg0RU9o2bpA==",
        // CIOBANU MARIA, until 11/2029
        "MIIB2DCCAX6gAwIBAgICB9IwCgYIKoZIzj0EAwIwPzELMAkGA1UEBhMCTUQxHjAcBgNVBAoMFWVTZW1uQnVuIGRlbW8gZml4dHVyZTEQMA4GA1UEAwwHTURRU2lnbjAeFw0yNjEwMjUxMDQ5MTRaFw0yOTExMDExMDQ5MTRaMGcxCzAJBgNVBAYTAk1EMR4wHAYDVQQKDBVlU2VtbkJ1biBkZW1vIGZpeHR1cmUxEDAOBgNVBAQMB0NJT0JBTlUxDjAMBgNVBCoMBU1BUklBMRYwFAYDVQQDDA1DSU9CQU5VIE1BUklBMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEIMNsMN2hLqX53/QZA844Z1BLV+p0ujzx4cTyrAbkpOUyeV/x1bY8wWG/GGGaozLA0D2jkhE4acB8aciXcMgRHKNCMEAwHQYDVR0OBBYEFCZugXIQYJgVifdYpG1ApJCmHNbYMB8GA1UdIwQYMBaAFBeujuMFlKgnaHUNrK6IpwUEEifaMAoGCCqGSM49BAMCA0gAMEUCIQDd7CSXY0hnJaXc90UXweSw/6vOtaGR8GtMrRLL4koquAIgKtLxCGy19b56pu+d7FBeiJT7/rHoet15GDGZn2flf5E=",
        // ROTARU ANDREI, until 06/2028
        "MIIB2DCCAX6gAwIBAgICB9MwCgYIKoZIzj0EAwIwPzELMAkGA1UEBhMCTUQxHjAcBgNVBAoMFWVTZW1uQnVuIGRlbW8gZml4dHVyZTEQMA4GA1UEAwwHTURRU2lnbjAeFw0yNjEwMjUxMDQ5MTRaFw0yODA2MTkxMDQ5MTRaMGcxCzAJBgNVBAYTAk1EMR4wHAYDVQQKDBVlU2VtbkJ1biBkZW1vIGZpeHR1cmUxDzANBgNVBAQMBlJPVEFSVTEPMA0GA1UEKgwGQU5EUkVJMRYwFAYDVQQDDA1ST1RBUlUgQU5EUkVJMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEH0L1lXi1fqJigZvjmPWbKfYT7nSxPj/csX1oOGYPKDvHZPXOIUNKK8BC4pd0aS9d8r8/5cvDLTigTRxK9xz4rKNCMEAwHQYDVR0OBBYEFNo4vcf8aRXTLTfMk3k/Xz6l5M6NMB8GA1UdIwQYMBaAFBeujuMFlKgnaHUNrK6IpwUEEifaMAoGCCqGSM49BAMCA0gAMEUCIQCUc4T/oGfOxBbiEVvQfq5Mh89xF9VxRAwso7NWTjUBlAIgCWwWqg8avyDMtNDSqvLh+ZewGGSkooKRJAm6bEur88U=",
        // MÎNDRU ȘTEFAN, until 01/2031
        "MIIB2zCCAYKgAwIBAgICB9QwCgYIKoZIzj0EAwIwPzELMAkGA1UEBhMCTUQxHjAcBgNVBAoMFWVTZW1uQnVuIGRlbW8gZml4dHVyZTEQMA4GA1UEAwwHTURRU2lnbjAeFw0yNjEwMjUxMDU3NDNaFw0zMTAxMTQxMDU3NDNaMGsxCzAJBgNVBAYTAk1EMR4wHAYDVQQKDBVlU2VtbkJ1biBkZW1vIGZpeHR1cmUxEDAOBgNVBAQMB03Djk5EUlUxEDAOBgNVBCoMB8iYVEVGQU4xGDAWBgNVBAMMD03Djk5EUlUgyJhURUZBTjBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABKGfiD8oWDHd3yNUy8oX+nbarKEQ+IFp5KfkG2bGpvIc8+PtMGRiHupk3uDs2XJOwisDd74PwugcqWlKQdc6+GSjQjBAMB0GA1UdDgQWBBTpx5ufVV6QvSv/z7UJwzkMig0GeDAfBgNVHSMEGDAWgBQwBq4FMpeN/41slktiRMNyorYQZzAKBggqhkjOPQQDAgNHADBEAiA1v+PKvjw+utszYzYD8v5iGbWasnFeuGiomA+kDq4XvwIgC03ggPaf2cBPWcdimJNL/A+KfQStJybrkehktCubkk4=",
    ]
}
#endif
