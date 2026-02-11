import Foundation
import RealmSwift

final class RealmStorageService: NewsStorageServiceProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    private let configuration: Realm.Configuration
    private let queue: DispatchQueue
    
    // MARK: - Initialization
    init(configuration: Realm.Configuration? = nil) {
        let config = configuration ?? Self.defaultConfiguration()
        self.configuration = config
        self.queue = DispatchQueue(label: "com.newsconsolidator.realm", qos: .userInitiated)
        
        Realm.Configuration.defaultConfiguration = config
    }
    
    private static func defaultConfiguration() -> Realm.Configuration {
        Realm.Configuration(schemaVersion: 2, migrationBlock: { migration, oldSchemaVersion in
            if oldSchemaVersion < 2 {
                
            }
        }
        )
    }
    
    // MARK: - Private Helpers
    private func getRealm() throws -> Realm {
        do {
            return try Realm(configuration: configuration)
        } catch {
            throw AppError.databaseInitializationFailed
        }
    }
    
    // MARK: - NewsStorageServiceProtocol
    func saveNewsItems(_ items: [NewsItemDTO]) throws {
        
        let realm = try getRealm()
        
        do {
            try realm.write {
                for dto in items {
                    if let existing = realm.object(ofType: NewsItemEntity.self, forPrimaryKey: dto.id) {
                        existing.update(from: dto)
                    } else {
                        let entity = NewsItemEntity(from: dto)
                        realm.add(entity)
                    }
                }
            }
        } catch {
            throw AppError.databaseError(underlying: error)
        }
    }
    
    func fetchAllNews(enabledSources: Set<String>?) throws -> [NewsItemDTO] {
        
        let realm = try getRealm()
        var results = realm.objects(NewsItemEntity.self)
        
        if let sources = enabledSources, !sources.isEmpty {
            results = results.filter("sourceIdentifier IN %@", Array(sources))
        }
        
        return results
            .sorted(byKeyPath: "pubDate", ascending: false)
            .map { $0.toDTO() }
    }
    
    func markAsRead(byId id: String) throws {
        
        let realm = try getRealm()
        
        guard let entity = realm.object(ofType: NewsItemEntity.self, forPrimaryKey: id) else {
            throw AppError.objectNotFound
        }
        
        guard !entity.isInvalidated else {
            throw AppError.objectInvalidated
        }
        
        do {
            try realm.write {
                entity.isRead = true
            }
        } catch {
            throw AppError.databaseError(underlying: error)
        }
    }
    
    func deleteAllNews() throws {
        let realm = try getRealm()
        
        do {
            try realm.write {
                realm.delete(realm.objects(NewsItemEntity.self))
            }
        } catch {
            throw AppError.databaseError(underlying: error)
        }
    }
    
    func newsCount() throws -> Int {
        let realm = try getRealm()
        return realm.objects(NewsItemEntity.self).count
    }
    
}

// MARK: - Thread-safe convenience methods
extension RealmStorageService {
    
    func saveNewsItemsAsync(_ items: [NewsItemDTO]) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: AppError.unknown(underlying: nil))
                    return
                }
                
                do {
                    try self.saveNewsItems(items)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func fetchAllNewsAsync(enabledSources: Set<String>?) async throws -> [NewsItemDTO] {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[NewsItemDTO], Error>) in
            queue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: AppError.unknown(underlying: nil))
                    return
                }
                
                do {
                    let items = try self.fetchAllNews(enabledSources: enabledSources)
                    continuation.resume(returning: items)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
}
