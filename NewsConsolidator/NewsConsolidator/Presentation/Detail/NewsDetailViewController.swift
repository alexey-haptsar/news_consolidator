import UIKit

final class NewsDetailViewController: GradientViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let sourceLabel = UILabel()
    private let dateLabel = UILabel()
    private let openButton = UIButton(type: .system)
    
    private var imageHeightConstraint: NSLayoutConstraint?
    
    // MARK: - Properties
    private let newsItem: NewsItemDTO
    private let imageService: ImageCacheServiceProtocol
    private let storageService: NewsStorageServiceProtocol
    
    // MARK: - Initialization
    init(newsItem: NewsItemDTO, imageService: ImageCacheServiceProtocol, storageService: NewsStorageServiceProtocol) {
        self.newsItem = newsItem
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
        
        title = newsItem.sourceName
        
        setupScrollView()
        setupContentViews()
        setupConstraints()
        configureContent()
        markAsRead()
    }
    
    // MARK: - Setup
    private func setupScrollView() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
    }
    
    private func setupContentViews() {
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = Theme.separator
        imageView.layer.cornerRadius = 12
        imageView.isHidden = !newsItem.hasImage
        contentView.addSubview(imageView)
        
        sourceLabel.translatesAutoresizingMaskIntoConstraints = false
        sourceLabel.font = Theme.captionFont
        sourceLabel.textColor = Theme.sourceColor(for: newsItem.sourceName)
        contentView.addSubview(sourceLabel)
        
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.font = Theme.captionFont
        dateLabel.textColor = Theme.tertiaryText
        contentView.addSubview(dateLabel)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = Theme.primaryText
        titleLabel.numberOfLines = 0
        contentView.addSubview(titleLabel)
        
        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = Theme.bodyFont
        descriptionLabel.textColor = Theme.secondaryText
        descriptionLabel.numberOfLines = 0
        contentView.addSubview(descriptionLabel)
        
        openButton.translatesAutoresizingMaskIntoConstraints = false
        openButton.setTitle("Open in Browser", for: .normal)
        openButton.setTitleColor(Theme.primaryText, for: .normal)
        openButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        openButton.backgroundColor = Theme.accent
        openButton.layer.cornerRadius = 12
        openButton.addTarget(self, action: #selector(openInBrowser), for: .touchUpInside)
        contentView.addSubview(openButton)
    }
    
    private func setupConstraints() {
        let hasImage = newsItem.hasImage
        let hasDescription = newsItem.hasDescription
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16).isActive = true
        
        let imgHeight = imageView.heightAnchor.constraint(equalToConstant: 0)
        imgHeight.isActive = true
        imageHeightConstraint = imgHeight
        
        if hasImage {
            let widthGuess = UIScreen.main.bounds.width - 32
            imageHeightConstraint?.constant = widthGuess * 9.0 / 16.0
        }
        
        let topAnchorForSource = hasImage ? imageView.bottomAnchor : contentView.topAnchor
        let topConstant: CGFloat = 16
        
        NSLayoutConstraint.activate([
            sourceLabel.topAnchor.constraint(equalTo: topAnchorForSource, constant: topConstant),
            sourceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            
            dateLabel.leadingAnchor.constraint(equalTo: sourceLabel.trailingAnchor, constant: 12),
            dateLabel.centerYAnchor.constraint(equalTo: sourceLabel.centerYAnchor),
            dateLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -16),
            
            titleLabel.topAnchor.constraint(equalTo: sourceLabel.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            descriptionLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            descriptionLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            openButton.topAnchor.constraint(
                equalTo: hasDescription ? descriptionLabel.bottomAnchor : titleLabel.bottomAnchor,
                constant: 24
            ),
            openButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            openButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            openButton.heightAnchor.constraint(equalToConstant: 50),
            openButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -24)
        ])
    }
    
    private func configureContent() {
        titleLabel.text = newsItem.title
        descriptionLabel.isHidden = !newsItem.hasDescription
        descriptionLabel.text = newsItem.descriptionText
        sourceLabel.text = newsItem.sourceName
        dateLabel.text = DateFormatter.newsDetail.string(from: newsItem.pubDate)
        
        if let imageURLString = newsItem.imageURL?.absoluteString {
            imageService.loadImage(from: imageURLString) { [weak self] image, fromCache in
                guard let self = self, let image = image else { return }
                if fromCache {
                    self.imageView.image = image
                } else {
                    self.imageView.alpha = 0
                    self.imageView.image = image
                    UIView.animate(withDuration: 0.3) {
                        self.imageView.alpha = 1
                    }
                }
            }
        }
        
        openButton.isHidden = newsItem.link == nil
    }
    
    private func markAsRead() {
        do {
            try storageService.markAsRead(byId: newsItem.id)
        } catch {
            print("Failed to mark as read: \(error)")
        }
    }
    
    // MARK: - Actions
    @objc private func openInBrowser() {
        guard let url = newsItem.link else { return }
        UIApplication.shared.open(url)
    }
    
}
