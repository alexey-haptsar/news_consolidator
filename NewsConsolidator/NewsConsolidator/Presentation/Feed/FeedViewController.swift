import UIKit
import AsyncDisplayKit
import Combine

final class FeedViewController: GradientViewController {
    
    // MARK: - Properties
    private let tableNode = ASTableNode()
    private let refreshControl = UIRefreshControl()
    
    private let viewModel: FeedViewModel
    private weak var coordinator: FeedCoordinator?
    private var cancellables = Set<AnyCancellable>()
    
    private lazy var emptyStateLabel: UILabel = {
        let label = UILabel()
        
        label.text = "No news available.\nPull down to refresh."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.textColor = Theme.secondaryText
        label.font = Theme.bodyFont
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Initialization
    init(viewModel: FeedViewModel, coordinator: FeedCoordinator) {
        self.viewModel = viewModel
        self.coordinator = coordinator
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "News"
        
        setupTableNode()
        setupNavigationBar()
        setupRefreshControl()
        setupBindings()
        
        viewModel.loadNewsFromDB()
        
        Task {
            await viewModel.fetchNews()
        }
        
        viewModel.startRefreshTimer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadNewsFromDB()
    }
    
    // MARK: - Setup
    private func setupTableNode() {
        tableNode.delegate = self
        tableNode.dataSource = self
        tableNode.backgroundColor = .clear
        
        let tableView = tableNode.view
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        view.addSubview(emptyStateLabel)
        NSLayoutConstraint.activate([
            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }
    
    private func setupNavigationBar() {
        updateToggleButton()
        
        let refreshButton = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshTapped)
        )
        refreshButton.tintColor = Theme.accent
        navigationItem.leftBarButtonItem = refreshButton
    }
    
    private func updateToggleButton() {
        let imageName = viewModel.isExpandedMode ? "list.bullet" : "text.below.photo"
        let toggleButton = UIBarButtonItem(
            image: UIImage(systemName: imageName),
            style: .plain,
            target: self,
            action: #selector(toggleModeTapped)
        )
        toggleButton.tintColor = Theme.accent
        navigationItem.rightBarButtonItem = toggleButton
    }
    
    private func setupRefreshControl() {
        refreshControl.tintColor = Theme.accent
        refreshControl.addTarget(self, action: #selector(pullToRefresh), for: .valueChanged)
        tableNode.view.refreshControl = refreshControl
    }
    
    private func setupBindings() {
        viewModel.$newsItems
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.emptyStateLabel.isHidden = !items.isEmpty
                self?.tableNode.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                if !isLoading {
                    self?.refreshControl.endRefreshing()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$error
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] error in
                self?.showError(error)
                self?.viewModel.clearError()
            }
            .store(in: &cancellables)
        
        viewModel.$isExpandedMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateToggleButton()
                self?.tableNode.reloadData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Actions
    @objc private func toggleModeTapped() {
        viewModel.toggleMode()
    }
    
    @objc private func refreshTapped() {
        Task {
            await viewModel.fetchNews()
        }
    }
    
    @objc private func pullToRefresh() {
        Task {
            await viewModel.fetchNews()
        }
    }
    
}

// MARK: - ASTableDataSource
extension FeedViewController: ASTableDataSource {
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return viewModel.newsItems.count
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        let items = viewModel.newsItems
        guard indexPath.row < items.count else {
            return { ASCellNode() }
        }
        
        let item = items[indexPath.row]
        let expanded = viewModel.isExpandedMode
        
        return {
            NewsCellNode(item: item, isExpanded: expanded)
        }
    }
    
}

// MARK: - ASTableDelegate
extension FeedViewController: ASTableDelegate {
    
    func tableNode(_ tableNode: ASTableNode, didSelectRowAt indexPath: IndexPath) {
        tableNode.deselectRow(at: indexPath, animated: true)
        
        let items = viewModel.newsItems
        guard indexPath.row < items.count else { return }
        
        let item = items[indexPath.row]
        viewModel.markAsRead(item)
        coordinator?.showNewsDetail(item)
    }
    
}
