import Foundation
import UIKit

final class DependencyContainer {
    
    // MARK: - Services
    let networkService: NewsNetworkServiceProtocol
    let storageService: NewsStorageServiceProtocol
    let settingsService: SettingsServiceProtocol
    let imageService: ImageCacheServiceProtocol
    
    // MARK: - Initialization
    init(networkService: NewsNetworkServiceProtocol, storageService: NewsStorageServiceProtocol, settingsService: SettingsServiceProtocol, imageService: ImageCacheServiceProtocol) {
        self.networkService = networkService
        self.storageService = storageService
        self.settingsService = settingsService
        self.imageService = imageService
    }
    
    // MARK: - Factory
    static func makeDefault() -> DependencyContainer {
        DependencyContainer(networkService: RSSParserService(), storageService: RealmStorageService(), settingsService: SettingsService(), imageService: ImageCacheService())
    }
    
}
