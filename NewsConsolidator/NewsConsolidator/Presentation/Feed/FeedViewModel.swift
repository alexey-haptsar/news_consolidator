import Foundation
import Combine

@MainActor
final class FeedViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var newsItems: [NewsItemDTO] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: AppError?
    @Published var isExpandedMode: Bool = false
    
    // MARK: - Properties
    var isEmpty: Bool {
        newsItems.isEmpty
    }
    
    private let networkService: NewsNetworkServiceProtocol
    private let storageService: NewsStorageServiceProtocol
    private let settingsService: SettingsServiceProtocol
    private let notificationCenter: NotificationCenter
    
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(networkService: NewsNetworkServiceProtocol, storageService: NewsStorageServiceProtocol, settingsService: SettingsServiceProtocol, notificationCenter: NotificationCenter = .default) {
        self.networkService = networkService
        self.storageService = storageService
        self.settingsService = settingsService
        self.notificationCenter = notificationCenter
        
        setupObservers()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
    
    // MARK: - Public Methods
    func loadNewsFromDB() {
        let enabled = settingsService.enabledSourceIdentifiers
        
        do {
            newsItems = try storageService.fetchAllNews(enabledSources: enabled)
        } catch {
            self.error = error as? AppError ?? AppError.databaseError(underlying: error)
        }
    }
    
    func fetchNews() async {
        let sources = settingsService.enabledSources()
        guard !sources.isEmpty else {
            loadNewsFromDB()
            return
        }
        
        isLoading = true
        error = nil
        
        let items = await networkService.fetchNewsFromAllSources(sources)
        
        do {
            try storageService.saveNewsItems(items)
            loadNewsFromDB()
        } catch {
            self.error = error as? AppError ?? AppError.databaseError(underlying: error)
        }
        
        isLoading = false
    }
    
    func markAsRead(_ item: NewsItemDTO) {
        guard !item.isRead else { return }
        
        do {
            try storageService.markAsRead(byId: item.id)
            if let index = newsItems.firstIndex(where: { $0.id == item.id }) {
                newsItems[index].isRead = true
            }
        } catch {
            print("Failed to mark as read: \(error)")
        }
    }
    
    func toggleMode() {
        isExpandedMode.toggle()
    }
    
    func startRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        
        let interval = settingsService.refreshInterval
        guard interval != .manual else { return }
        
        refreshTimer = Timer.scheduledTimer(
            withTimeInterval: TimeInterval(interval.rawValue),
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.fetchNews()
            }
        }
    }
    
    func clearError() {
        error = nil
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        notificationCenter.publisher(for: .refreshIntervalChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.startRefreshTimer()
            }
            .store(in: &cancellables)
        
        notificationCenter.publisher(for: .enabledSourcesChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.loadNewsFromDB()
                Task { @MainActor [weak self] in
                    await self?.fetchNews()
                }
            }
            .store(in: &cancellables)
    }
    
}
