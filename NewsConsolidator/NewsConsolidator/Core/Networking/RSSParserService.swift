import Foundation

final class RSSParserService: NewsNetworkServiceProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    private let urlSession: URLSession
    private let timeoutInterval: TimeInterval
    
    // MARK: - Initialization
    init(urlSession: URLSession = .shared, timeoutInterval: TimeInterval = 30) {
        self.urlSession = urlSession
        self.timeoutInterval = timeoutInterval
    }
    
    // MARK: - NewsNetworkServiceProtocol
    func fetchNews(from source: NewsSourceDTO) async throws -> [NewsItemDTO] {
        guard let url = source.url else {
            throw AppError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = timeoutInterval
        
        do {
            let (data, response) = try await urlSession.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.invalidResponse(statusCode: 0)
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                throw AppError.invalidResponse(statusCode: httpResponse.statusCode)
            }
            
            return parseRSS(data: data, source: source)
        } catch let error as AppError {
            throw error
        } catch let error as URLError where error.code == .timedOut {
            throw AppError.requestTimeout
        } catch {
            throw AppError.networkError(underlying: error)
        }
    }
    
    func fetchNewsFromAllSources(_ sources: [NewsSourceDTO]) async -> [NewsItemDTO] {
        await withTaskGroup(of: [NewsItemDTO].self) { group in
            for source in sources {
                group.addTask { [weak self] in
                    guard let self = self else { return [] }
                    do {
                        return try await self.fetchNews(from: source)
                    } catch {
                        print("Failed to fetch from \(source.name): \(error.localizedDescription)")
                        return []
                    }
                }
            }
            
            var allItems: [NewsItemDTO] = []
            for await items in group {
                allItems.append(contentsOf: items)
            }
            
            return allItems.sorted { $0.pubDate > $1.pubDate }
        }
    }
    
    // MARK: - Private Methods
    private func parseRSS(data: Data, source: NewsSourceDTO) -> [NewsItemDTO] {
        let delegate = RSSXMLParserDelegate(source: source)
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.items
    }
    
}

// MARK: - XML Parser Delegate
private final class RSSXMLParserDelegate: NSObject, XMLParserDelegate {
    
    let source: NewsSourceDTO
    private(set) var items: [NewsItemDTO] = []
    
    private var currentElement = ""
    private var currentTitle = ""
    private var currentDescription = ""
    private var currentLink = ""
    private var currentPubDate = ""
    private var currentImageURL = ""
    private var isInsideItem = false
    
    init(source: NewsSourceDTO) {
        self.source = source
        super.init()
    }
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        
        currentElement = elementName
        
        if elementName == "item" {
            isInsideItem = true
            currentTitle = ""
            currentDescription = ""
            currentLink = ""
            currentPubDate = ""
            currentImageURL = ""
        }
        
        if isInsideItem {
            if elementName == "enclosure" {
                if let type = attributeDict["type"], type.hasPrefix("image"),
                   let url = attributeDict["url"] {
                    currentImageURL = url
                }
            }
            
            let qualifiedOrElement = qName ?? elementName
            if qualifiedOrElement.contains("content") && qualifiedOrElement.contains("media") {
                if let url = attributeDict["url"], currentImageURL.isEmpty {
                    currentImageURL = url
                }
            }
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        guard isInsideItem else { return }
        
        switch currentElement {
        case "title":
            currentTitle += string
        case "description":
            currentDescription += string
        case "link":
            currentLink += string
        case "pubDate":
            currentPubDate += string
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, foundCDATA CDATABlock: Data) {
        guard isInsideItem else { return }
        guard let string = String(data: CDATABlock, encoding: .utf8) else { return }
        
        switch currentElement {
        case "title":
            currentTitle += string
        case "description":
            currentDescription += string
        case "link":
            currentLink += string
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser,didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        
        guard elementName == "item", isInsideItem else { return }
        isInsideItem = false
        
        let title = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawDescription = currentDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        let description = stripHTML(rawDescription)
        let link = currentLink.trimmingCharacters(in: .whitespacesAndNewlines)
        let pubDate = DateFormatter.parseRSSDate(currentPubDate.trimmingCharacters(in: .whitespacesAndNewlines))
        
        var imageURL = currentImageURL.trimmingCharacters(in: .whitespacesAndNewlines)
        if imageURL.isEmpty {
            imageURL = extractImageURL(from: currentDescription) ?? ""
        }
        
        guard !title.isEmpty else { return }
        
        let item = NewsItemDTO(title: title, description: description, imageURLString: imageURL, linkString: link, pubDate: pubDate, source: source)
        
        items.append(item)
    }
    
    private func stripHTML(_ html: String) -> String {
        html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractImageURL(from html: String) -> String? {
        let pattern = "<img[^>]+src=[\"']([^\"']+)[\"']"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range) else { return nil }
        guard let urlRange = Range(match.range(at: 1), in: html) else { return nil }
        return String(html[urlRange])
    }
    
}
