/// No credential storage or Secret Service access in an interactive mock workflow.
final class DemoPINStore: PINStoring {
    func save(_ pin: String, certID: String, holder: String) throws {}
    func load(certID: String) -> PINLookup { .missing }
    func hasPIN(certID: String) -> Bool { false }
    func delete(certID: String) -> Bool { true }
    func deleteAll() -> Bool { true }
    func availabilityProblem() -> String? { nil }
}
