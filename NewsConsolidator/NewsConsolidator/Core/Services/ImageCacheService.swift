import UIKit

final class ImageCacheService: ImageCacheServiceProtocol {
    
    // MARK: - Properties
    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheQueue = DispatchQueue(label: "com.newsconsolidator.imagecache", qos: .userInitiated)
    private var activeTasks: [String: URLSessionDataTask] = [:]
    private let taskLock = NSLock()
    
    private let urlSession: URLSession
    private let diskCacheURL: URL
    
    // MARK: - Initialization
    init(memoryCacheCountLimit: Int = 100, memoryCacheTotalCostLimit: Int = 50 * 1024 * 1024, httpMaximumConnectionsPerHost: Int = 8, timeoutIntervalForRequest: TimeInterval = 15) {
        
        memoryCache.countLimit = memoryCacheCountLimit
        memoryCache.totalCostLimit = memoryCacheTotalCostLimit
        
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = httpMaximumConnectionsPerHost
        config.timeoutIntervalForRequest = timeoutIntervalForRequest
        config.urlCache = nil
        self.urlSession = URLSession(configuration: config)
        
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.diskCacheURL = cacheDir.appendingPathComponent("ImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
    
    // MARK: - ImageCacheServiceProtocol
    func loadImage(from urlString: String, completion: @escaping (_ image: UIImage?, _ fromCache: Bool) -> Void) {
        guard !urlString.isEmpty, URL(string: urlString) != nil else {
            DispatchQueue.main.async { completion(nil, false) }
            return
        }
        
        let key = cacheKey(for: urlString)
        
        if let cached = memoryCache.object(forKey: key as NSString) {
            DispatchQueue.main.async { completion(cached, true) }
            return
        }
        
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            
            if let diskImage = self.loadFromDisk(key: key) {
                self.memoryCache.setObject(diskImage, forKey: key as NSString)
                DispatchQueue.main.async { completion(diskImage, true) }
                return
            }
            
            guard let url = URL(string: urlString) else {
                DispatchQueue.main.async { completion(nil, false) }
                return
            }
            
            self.downloadImage(url: url, key: key, completion: completion)
        }
    }
    
    func cancelLoad(for urlString: String) {
        let key = cacheKey(for: urlString)
        taskLock.lock()
        activeTasks[key]?.cancel()
        activeTasks.removeValue(forKey: key)
        taskLock.unlock()
    }
    
    func clearCache() {
        memoryCache.removeAllObjects()
        cacheQueue.async { [weak self] in
            guard let self = self else { return }
            try? self.fileManager.removeItem(at: self.diskCacheURL)
            try? self.fileManager.createDirectory(at: self.diskCacheURL, withIntermediateDirectories: true)
        }
    }
    
    func cacheSize() -> Int64 {
        guard let files = try? fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.fileSizeKey]) else { return 0 }
        
        return files.reduce(into: Int64(0)) { total, fileURL in
            let size = (try? fileURL.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            total += Int64(size)
        }
    }
    
    // MARK: - Private Methods
    private func downloadImage(url: URL, key: String, completion: @escaping (_ image: UIImage?, _ fromCache: Bool) -> Void) {
        let task = urlSession.dataTask(with: url) { [weak self] data, _, error in
            guard let self = self else { return }
            
            self.taskLock.lock()
            self.activeTasks.removeValue(forKey: key)
            self.taskLock.unlock()
            
            guard let data = data, error == nil, let image = UIImage(data: data) else {
                DispatchQueue.main.async { completion(nil, false) }
                return
            }
            
            self.memoryCache.setObject(image, forKey: key as NSString)
            self.saveToDisk(data: data, key: key)
            
            DispatchQueue.main.async { completion(image, false) }
        }
        
        taskLock.lock()
        activeTasks[key] = task
        taskLock.unlock()
        
        task.resume()
    }
    
    private func loadFromDisk(key: String) -> UIImage? {
        let fileURL = diskCacheURL.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: data)
    }
    
    private func saveToDisk(data: Data, key: String) {
        let fileURL = diskCacheURL.appendingPathComponent(key)
        try? data.write(to: fileURL, options: .atomic)
    }
    
    private func cacheKey(for urlString: String) -> String {
        guard let data = urlString.data(using: .utf8) else { return urlString }
        return data.base64EncodedString()
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "=", with: "")
    }
    
}
