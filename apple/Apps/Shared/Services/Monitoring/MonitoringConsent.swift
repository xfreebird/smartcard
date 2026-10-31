import Foundation

/// Unknown is distinct from a recorded decline. One atomic preference owns both independent choices.
struct MonitoringConsent: Equatable {
    var decided = false
    var crashes = false
    var metrics = false
    var canStart: Bool { decided && (crashes || metrics) }
    enum Category { case crashes, metrics }
    func permits(_ category: Category) -> Bool { decided && (category == .crashes ? crashes : metrics) }

    static let preferenceKey = "monitoringConsent.v1"

    static func load(from defaults: UserDefaults) -> Self {
        guard let value = defaults.dictionary(forKey: preferenceKey), value["decided"] as? Bool == true else { return Self() }
        return Self(decided: true, crashes: value["crashes"] as? Bool ?? false, metrics: value["metrics"] as? Bool ?? false)
    }

    func save(to defaults: UserDefaults) {
        defaults.set(["decided": decided, "crashes": decided && crashes, "metrics": decided && metrics], forKey: Self.preferenceKey)
    }
}
