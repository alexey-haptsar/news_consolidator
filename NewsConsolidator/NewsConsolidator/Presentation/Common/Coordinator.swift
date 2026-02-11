import UIKit

protocol Coordinator: AnyObject {
    
    var navigationController: UINavigationController { get }
    var childCoordinators: [Coordinator] { get set }
    
    func start()
    
}

extension Coordinator {
    
    func addChild(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
    }
    
    func removeChild(_ coordinator: Coordinator) {
        childCoordinators.removeAll { $0 === coordinator }
    }
    
}

// MARK: - App Coordinator
final class AppCoordinator: Coordinator {
    
    // MARK: - Properties
    let window: UIWindow
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    
    private let dependencies: DependencyContainer
    
    // MARK: - Initialization
    init(window: UIWindow, dependencies: DependencyContainer) {
        self.window = window
        self.dependencies = dependencies
        self.navigationController = UINavigationController()
    }
    
    // MARK: - Coordinator
    @MainActor func start() {
        let tabBarController = createTabBarController()
        window.rootViewController = tabBarController
        window.makeKeyAndVisible()
    }
    
    // MARK: - Private Methods
    @MainActor private func createTabBarController() -> UITabBarController {
        let tabBar = UITabBarController()
        
        let feedCoordinator = FeedCoordinator(dependencies: dependencies)
        addChild(feedCoordinator)
        feedCoordinator.start()
        feedCoordinator.navigationController.tabBarItem = UITabBarItem(title: "Feed", image: UIImage(systemName: "newspaper"), tag: 0)
        
        let settingsCoordinator = SettingsCoordinator(dependencies: dependencies)
        addChild(settingsCoordinator)
        settingsCoordinator.start()
        settingsCoordinator.navigationController.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape"), tag: 1)
        
        tabBar.viewControllers = [
            feedCoordinator.navigationController,
            settingsCoordinator.navigationController
        ]
        
        let tabBarAppearance = Theme.configureTabBarAppearance()
        tabBar.tabBar.standardAppearance = tabBarAppearance
        tabBar.tabBar.scrollEdgeAppearance = tabBarAppearance
        
        return tabBar
    }
    
}

// MARK: - Feed Coordinator
final class FeedCoordinator: Coordinator {
    
    // MARK: - Properties
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    
    private let dependencies: DependencyContainer
    
    // MARK: - Initialization
    init(navigationController: UINavigationController = UINavigationController(), dependencies: DependencyContainer) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }
    
    // MARK: - Coordinator
    @MainActor func start() {
        let viewModel = FeedViewModel(networkService: dependencies.networkService, storageService: dependencies.storageService, settingsService: dependencies.settingsService)
        let viewController = FeedViewController(viewModel: viewModel, coordinator: self)
        navigationController.setViewControllers([viewController], animated: false)
    }
    
    // MARK: - Navigation
    func showNewsDetail(_ item: NewsItemDTO) {
        let viewController = NewsDetailViewController(newsItem: item, imageService: dependencies.imageService, storageService: dependencies.storageService)
        navigationController.pushViewController(viewController, animated: true)
    }
    
}

// MARK: - Settings Coordinator
final class SettingsCoordinator: Coordinator {
    
    // MARK: - Properties
    let navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    
    private let dependencies: DependencyContainer
    
    // MARK: - Initialization
    init(navigationController: UINavigationController = UINavigationController(), dependencies: DependencyContainer) {
        self.navigationController = navigationController
        self.dependencies = dependencies
    }
    
    // MARK: - Coordinator
    func start() {
        let viewController = SettingsViewController(settingsService: dependencies.settingsService, imageService: dependencies.imageService, storageService: dependencies.storageService)
        
        navigationController.setViewControllers([viewController], animated: false)
    }
    
}
