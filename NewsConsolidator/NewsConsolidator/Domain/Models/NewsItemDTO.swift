import Foundation

struct NewsItemDTO: Hashable, Identifiable, Sendable {
    
    let id: String
    let title: String
    let descriptionText: String
    let imageURL: URL?
    let link: URL?
    let pubDate: Date
    let sourceIdentifier: String
    let sourceName: String
    var isRead: Bool
    
    // MARK: - Initialization
    init(id: String, title: String, descriptionText: String, imageURL: URL?, link: URL?, pubDate: Date, sourceIdentifier: String, sourceName: String, isRead: Bool = false) {
        self.id = id
        self.title = title
        self.descriptionText = descriptionText
        self.imageURL = imageURL
        self.link = link
        self.pubDate = pubDate
        self.sourceIdentifier = sourceIdentifier
        self.sourceName = sourceName
        self.isRead = isRead
    }
    
    init(title: String, description: String, imageURLString: String, linkString: String, pubDate: Date, source: NewsSourceDTO) {
        let linkURL = URL(string: linkString)
        self.id = linkString.isEmpty ? UUID().uuidString : linkString
        self.title = title
        self.descriptionText = description
        self.imageURL = URL(string: imageURLString)
        self.link = linkURL
        self.pubDate = pubDate
        self.sourceIdentifier = source.identifier
        self.sourceName = source.name
        self.isRead = false
    }
    
    // MARK: - Computed Properties
    var hasImage: Bool {
        imageURL != nil
    }
    
    var hasDescription: Bool {
        !descriptionText.isEmpty
    }
    
    var imageURLString: String {
        imageURL?.absoluteString ?? ""
    }
    
    var linkString: String {
        link?.absoluteString ?? ""
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: NewsItemDTO, rhs: NewsItemDTO) -> Bool {
        lhs.id == rhs.id
    }
    
}
