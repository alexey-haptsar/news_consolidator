import Foundation

protocol NewsNetworkServiceProtocol: Sendable {
    
    func fetchNews(from source: NewsSourceDTO) async throws -> [NewsItemDTO]
    func fetchNewsFromAllSources(_ sources: [NewsSourceDTO]) async -> [NewsItemDTO]
    
}

protocol NewsStorageServiceProtocol: Sendable {
    
    func saveNewsItems(_ items: [NewsItemDTO]) throws
    func fetchAllNews(enabledSources: Set<String>?) throws -> [NewsItemDTO]
    func markAsRead(byId id: String) throws
    func deleteAllNews() throws
    func newsCount() throws -> Int
    
}

protocol SettingsServiceProtocol: AnyObject {
    
    var refreshInterval: RefreshInterval { get set }
    var enabledSourceIdentifiers: Set<String> { get set }
    func isSourceEnabled(_ source: NewsSourceDTO) -> Bool
    func setSource(_ source: NewsSourceDTO, enabled: Bool)
    func enabledSources() -> [NewsSourceDTO]
    
}

enum RefreshInterval: Int, CaseIterable, Sendable {
    case oneMinute = 60
    case fiveMinutes = 300
    case fifteenMinutes = 900
    case thirtyMinutes = 1800
    case oneHour = 3600
    case manual = 0
    
    var displayName: String {
        switch self {
            case .oneMinute: return "1 Minute"
            case .fiveMinutes: return "5 Minutes"
            case .fifteenMinutes: return "15 Minutes"
            case .thirtyMinutes: return "30 Minutes"
            case .oneHour: return "1 Hour"
            case .manual: return "Manual Only"
        }
    }
    
}
