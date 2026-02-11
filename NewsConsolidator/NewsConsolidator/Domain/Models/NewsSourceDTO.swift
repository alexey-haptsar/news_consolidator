import Foundation

struct NewsSourceDTO: Codable, Equatable, Hashable, Identifiable {
    
    let identifier: String
    let name: String
    let urlString: String
    
    var id: String { identifier }
    
    var url: URL? {
        URL(string: urlString)
    }
    
    // MARK: - Predefined Sources
    static let vedomosti = NewsSourceDTO(identifier: "vedomosti", name: "Vedomosti", urlString: "https://www.vedomosti.ru/rss/news")
    
    static let rbc = NewsSourceDTO(identifier: "rbc", name: "RBC", urlString: "https://rssexport.rbc.ru/rbcnews/news/30/full.rss")
    
    static let allSources: [NewsSourceDTO] = [.vedomosti, .rbc]
    
    // MARK: - Convenience
    static func source(for identifier: String) -> NewsSourceDTO? {
        allSources.first { $0.identifier == identifier }
    }
    
}
