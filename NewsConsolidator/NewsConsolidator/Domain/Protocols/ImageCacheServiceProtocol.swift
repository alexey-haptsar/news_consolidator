import UIKit

protocol ImageCacheServiceProtocol: AnyObject {
    
    func loadImage(from urlString: String, completion: @escaping (_ image: UIImage?, _ fromCache: Bool) -> Void)
    func loadImage(from urlString: String) async -> (image: UIImage?, fromCache: Bool)
    func cancelLoad(for urlString: String)
    func clearCache()
    func cacheSize() -> Int64
    
}

// MARK: - Default async implementation
extension ImageCacheServiceProtocol {
    
    func loadImage(from urlString: String) async -> (image: UIImage?, fromCache: Bool) {
        await withCheckedContinuation { continuation in
            loadImage(from: urlString) { image, fromCache in
                continuation.resume(returning: (image, fromCache))
            }
        }
    }
    
}
