import UIKit
import AsyncDisplayKit

final class NewsCellNode: ASCellNode {
    
    // MARK: - Nodes
    private let imageNode = ASImageNode()
    private let titleNode = ASTextNode()
    private let descriptionNode = ASTextNode()
    private let sourceNode = ASTextNode()
    private let dateNode = ASTextNode()
    private let cardNode = ASDisplayNode()
    private let readIndicatorNode = ASDisplayNode()
    
    // MARK: - Properties
    private let imageURLString: String?
    private let hasImage: Bool
    private let isExpanded: Bool
    private let hasDescription: Bool
    private let isReadItem: Bool
    
    // MARK: - Dependency
    private static var imageService: ImageCacheServiceProtocol = ImageCacheService()
    
    static func setImageService(_ service: ImageCacheServiceProtocol) {
        imageService = service
    }
    
    // MARK: - Initialization
    init(item: NewsItemDTO, isExpanded: Bool) {
        self.imageURLString = item.imageURLString.isEmpty ? nil : item.imageURLString
        self.isExpanded = isExpanded
        self.hasImage = item.hasImage
        self.hasDescription = isExpanded && item.hasDescription
        self.isReadItem = item.isRead
        super.init()
        
        automaticallyManagesSubnodes = true
        selectionStyle = .none
        backgroundColor = .clear
        
        configureCard(isRead: item.isRead)
        configureImage()
        configureTitle(title: item.title, isRead: item.isRead)
        configureSource(name: item.sourceName)
        configureDate(date: item.pubDate)
        configureReadIndicator(isRead: item.isRead)
        
        if hasDescription {
            configureDescription(text: item.descriptionText)
        }
        
        loadImageIfNeeded()
    }
    
    // MARK: - Lifecycle
    override func didLoad() {
        super.didLoad()
        cardNode.layer.cornerRadius = 12
        cardNode.clipsToBounds = true
    }
    
    override func didExitVisibleState() {
        super.didExitVisibleState()
        if let urlString = imageURLString {
            Self.imageService.cancelLoad(for: urlString)
        }
    }
    
    // MARK: - Configuration
    private func configureCard(isRead: Bool) {
        cardNode.backgroundColor = isRead ? Theme.cardBackgroundRead : Theme.cardBackground
    }
    
    private func configureImage() {
        imageNode.contentMode = .scaleAspectFill
        imageNode.backgroundColor = Theme.separator
        imageNode.cornerRadius = 8
        imageNode.clipsToBounds = true
    }
    
    private func loadImageIfNeeded() {
        guard let urlString = imageURLString else { return }
        
        Self.imageService.loadImage(from: urlString) { [weak self] image, fromCache in
            guard let self = self, let image = image else { return }
            if fromCache {
                self.imageNode.image = image
            } else {
                self.imageNode.alpha = 0
                self.imageNode.image = image
                UIView.animate(withDuration: 0.25) {
                    self.imageNode.alpha = 1
                }
            }
        }
    }
    
    private func configureTitle(title: String, isRead: Bool) {
        let color = isRead ? Theme.secondaryText : Theme.primaryText
        titleNode.attributedText = NSAttributedString(
            string: title,
            attributes: [
                .font: Theme.titleFont,
                .foregroundColor: color
            ]
        )
        titleNode.maximumNumberOfLines = 0
    }
    
    private func configureDescription(text: String) {
        descriptionNode.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .font: Theme.bodyFont,
                .foregroundColor: Theme.secondaryText
            ]
        )
        descriptionNode.maximumNumberOfLines = 3
    }
    
    private func configureSource(name: String) {
        sourceNode.attributedText = NSAttributedString(
            string: name,
            attributes: [
                .font: Theme.captionFont,
                .foregroundColor: Theme.sourceColor(for: name)
            ]
        )
    }
    
    private func configureDate(date: Date) {
        dateNode.attributedText = NSAttributedString(
            string: DateFormatter.newsCell.string(from: date),
            attributes: [
                .font: Theme.captionFont,
                .foregroundColor: Theme.tertiaryText
            ]
        )
    }
    
    private func configureReadIndicator(isRead: Bool) {
        readIndicatorNode.backgroundColor = isRead ? .clear : Theme.accent
        readIndicatorNode.cornerRadius = 4
    }
    
    // MARK: - Layout
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        var sourceChildren: [ASLayoutElement] = []
        if !isReadItem {
            readIndicatorNode.style.preferredSize = CGSize(width: 8, height: 8)
            sourceChildren.append(readIndicatorNode)
        }
        sourceChildren.append(sourceNode)
        
        let sourceInfoSpec = ASStackLayoutSpec(direction: .horizontal, spacing: 6, justifyContent: .start, alignItems: .center, children: sourceChildren)
        
        let metaSpec = ASStackLayoutSpec(direction: .horizontal, spacing: 8, justifyContent: .spaceBetween, alignItems: .center, children: [sourceInfoSpec, dateNode])
        
        let titleStack = ASStackLayoutSpec(direction: .vertical, spacing: 6, justifyContent: .start, alignItems: .stretch, children: [metaSpec, titleNode])
        titleStack.style.flexShrink = 1
        titleStack.style.flexGrow = 1
        
        let topRow: ASLayoutSpec
        if hasImage {
            imageNode.style.preferredSize = CGSize(width: 80, height: 80)
            topRow = ASStackLayoutSpec(direction: .horizontal, spacing: 12, justifyContent: .start, alignItems: .start, children: [imageNode, titleStack])
        } else {
            topRow = ASWrapperLayoutSpec(layoutElement: titleStack)
        }
        
        var mainChildren: [ASLayoutElement] = [topRow]
        if hasDescription {
            mainChildren.append(descriptionNode)
        }
        
        let mainStack = ASStackLayoutSpec(direction: .vertical, spacing: 8, justifyContent: .start, alignItems: .stretch, children: mainChildren)
        
        let padded = ASInsetLayoutSpec(insets: UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12), child: mainStack)
        
        let cardSpec = ASBackgroundLayoutSpec(child: padded, background: cardNode)
        
        return ASInsetLayoutSpec(insets: UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16), child: cardSpec)
    }
    
}
