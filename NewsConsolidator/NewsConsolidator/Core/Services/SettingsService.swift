import Foundation

final class SettingsService: SettingsServiceProtocol {
    
    // MARK: - Keys
    private enum Keys {
        static let refreshInterval = "settings.refreshInterval"
        static let enabledSources = "settings.enabledSources"
    }
    
    // MARK: - Properties
    private let defaults: UserDefaults
    private let notificationCenter: NotificationCenter
    
    // MARK: - Initialization
    init(defaults: UserDefaults = .standard, notificationCenter: NotificationCenter = .default) {
        self.defaults = defaults
        self.notificationCenter = notificationCenter
    }
    
    // MARK: - SettingsServiceProtocol
    var refreshInterval: RefreshInterval {
        get {
            let rawValue = defaults.integer(forKey: Keys.refreshInterval)
            return RefreshInterval(rawValue: rawValue) ?? .fiveMinutes
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.refreshInterval)
            notificationCenter.post(name: .refreshIntervalChanged, object: nil)
        }
    }
    
    var enabledSourceIdentifiers: Set<String> {
        get {
            if let array = defaults.stringArray(forKey: Keys.enabledSources) {
                return Set(array)
            }
            return Set(NewsSourceDTO.allSources.map { $0.identifier })
        }
        set {
            defaults.set(Array(newValue), forKey: Keys.enabledSources)
            notificationCenter.post(name: .enabledSourcesChanged, object: nil)
        }
    }
    
    func isSourceEnabled(_ source: NewsSourceDTO) -> Bool {
        enabledSourceIdentifiers.contains(source.identifier)
    }
    
    func setSource(_ source: NewsSourceDTO, enabled: Bool) {
        var identifiers = enabledSourceIdentifiers
        if enabled {
            identifiers.insert(source.identifier)
        } else {
            identifiers.remove(source.identifier)
        }
        enabledSourceIdentifiers = identifiers
    }
    
    func enabledSources() -> [NewsSourceDTO] {
        NewsSourceDTO.allSources.filter { isSourceEnabled($0) }
    }
    
}

// MARK: - Notification Names
extension Notification.Name {
    
    static let refreshIntervalChanged = Notification.Name("refreshIntervalChanged")
    static let enabledSourcesChanged = Notification.Name("enabledSourcesChanged")
    
}
