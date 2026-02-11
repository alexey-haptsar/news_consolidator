import UIKit

final class SettingsViewController: GradientViewController {
    
    // MARK: - Section
    private enum Section: Int, CaseIterable {
        
        case refreshInterval
        case sources
        case cache
        
        var title: String {
            
            switch self {
                case
                    .refreshInterval: return "Refresh Interval"
                case
                    .sources: return "News Sources"
                case
                    .cache: return "Cache"
            }
        }
        
    }
    
    // MARK: - Properties
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    private let settingsService: SettingsServiceProtocol
    private let imageService: ImageCacheServiceProtocol
    private let storageService: NewsStorageServiceProtocol
    
    // MARK: - Initialization
    init(settingsService: SettingsServiceProtocol, imageService: ImageCacheServiceProtocol, storageService: NewsStorageServiceProtocol) {
        self.settingsService = settingsService
        self.imageService = imageService
        self.storageService = storageService
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Settings"
        setupTableView()
    }
    
    // MARK: - Setup
    private func setupTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorColor = Theme.separator
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "SettingCell")
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    // MARK: - Helpers
    private func formattedCacheSize() -> String {
        let bytes = imageService.cacheSize()
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
}

// MARK: - UITableViewDataSource
extension SettingsViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sec = Section(rawValue: section) else { return 0 }
        switch sec {
        case .refreshInterval:
            return RefreshInterval.allCases.count
        case .sources:
            return NewsSourceDTO.allSources.count
        case .cache:
            return 2
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        cell.backgroundColor = Theme.cardBackground
        cell.textLabel?.textColor = Theme.primaryText
        cell.textLabel?.font = Theme.bodyFont
        cell.selectionStyle = .none
        cell.accessoryView = nil
        cell.accessoryType = .none
        
        let bgView = UIView()
        bgView.backgroundColor = Theme.cardBackgroundRead
        cell.selectedBackgroundView = bgView
        
        guard let section = Section(rawValue: indexPath.section) else { return cell }
        
        switch section {
        case .refreshInterval:
            let interval = RefreshInterval.allCases[indexPath.row]
            cell.textLabel?.text = interval.displayName
            if interval == settingsService.refreshInterval {
                cell.accessoryType = .checkmark
                cell.tintColor = Theme.accent
            }
            cell.selectionStyle = .default
            
        case .sources:
            let source = NewsSourceDTO.allSources[indexPath.row]
            cell.textLabel?.text = source.name
            
            let toggle = UISwitch()
            toggle.isOn = settingsService.isSourceEnabled(source)
            toggle.onTintColor = Theme.accent
            toggle.tag = indexPath.row
            toggle.addTarget(self, action: #selector(sourceToggleChanged(_:)), for: .valueChanged)
            cell.accessoryView = toggle
            
        case .cache:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Clear Image Cache (\(formattedCacheSize()))"
                cell.textLabel?.textColor = Theme.accent
                cell.selectionStyle = .default
            } else {
                cell.textLabel?.text = "Clear All Data"
                cell.textLabel?.textColor = Theme.destructive
                cell.selectionStyle = .default
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forHeaderInSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = Theme.secondaryText
        header.textLabel?.font = Theme.captionFont
    }
    
}

// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let section = Section(rawValue: indexPath.section) else { return }
        
        switch section {
        case .refreshInterval:
            handleRefreshIntervalSelection(at: indexPath)
            
        case .sources:
            break
            
        case .cache:
            if indexPath.row == 0 {
                clearImageCache()
            } else {
                clearAllData()
            }
        }
        
    }
    
    // MARK: - Actions
    private func handleRefreshIntervalSelection(at indexPath: IndexPath) {
        let allIntervals = RefreshInterval.allCases
        let newInterval = allIntervals[indexPath.row]
        let oldInterval = settingsService.refreshInterval
        guard newInterval != oldInterval else { return }
        
        let oldIndex = allIntervals.firstIndex(of: oldInterval)
        settingsService.refreshInterval = newInterval
        
        if let oldRow = oldIndex {
            let oldPath = IndexPath(row: oldRow, section: Section.refreshInterval.rawValue)
            tableView.cellForRow(at: oldPath)?.accessoryType = .none
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        tableView.cellForRow(at: indexPath)?.tintColor = Theme.accent
    }
    
    @objc private func sourceToggleChanged(_ sender: UISwitch) {
        let source = NewsSourceDTO.allSources[sender.tag]
        settingsService.setSource(source, enabled: sender.isOn)
    }
    
    private func clearImageCache() {
        showConfirmation(title: "Clear Image Cache", message: "Are you sure you want to clear the image cache?", confirmTitle: "Clear") { [weak self] in
            self?.imageService.clearCache()
            self?.tableView.reloadData()
        }
    }
    
    private func clearAllData() {
        showConfirmation(title: "Clear All Data", message: "This will delete all cached news and images. Continue?", confirmTitle: "Clear") { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.storageService.deleteAllNews()
                self.imageService.clearCache()
                self.tableView.reloadData()
                NotificationCenter.default.post(name: .enabledSourcesChanged, object: nil)
            } catch {
                self.showError(error)
            }
        }
    }
    
}
