import Foundation
import RealmSwift

final class NewsItemEntity: Object {
    
    @Persisted(primaryKey: true) var id: String = ""
    @Persisted var title: String = ""
    @Persisted var descriptionText: String = ""
    @Persisted var imageURL: String = ""
    @Persisted var link: String = ""
    @Persisted var pubDate: Date = Date()
    @Persisted var sourceIdentifier: String = ""
    @Persisted var sourceName: String = ""
    @Persisted var isRead: Bool = false
    
    // MARK: - Initialization
    convenience init(from dto: NewsItemDTO) {
        self.init()
        self.id = dto.id
        self.title = dto.title
        self.descriptionText = dto.descriptionText
        self.imageURL = dto.imageURLString
        self.link = dto.linkString
        self.pubDate = dto.pubDate
        self.sourceIdentifier = dto.sourceIdentifier
        self.sourceName = dto.sourceName
        self.isRead = dto.isRead
    }
    
    // MARK: - Mapping to DTO
    func toDTO() -> NewsItemDTO {
        NewsItemDTO(id: id, title: title, descriptionText: descriptionText, imageURL: URL(string: imageURL), link: URL(string: link), pubDate: pubDate, sourceIdentifier: sourceIdentifier, sourceName: sourceName, isRead: isRead)
    }
    
    // MARK: - Update from DTO
    func update(from dto: NewsItemDTO) {
        title = dto.title
        descriptionText = dto.descriptionText
        imageURL = dto.imageURLString
        pubDate = dto.pubDate
        sourceName = dto.sourceName
        sourceIdentifier = dto.sourceIdentifier
    }
    
}
