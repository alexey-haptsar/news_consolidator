import Foundation

enum AppError: Error, LocalizedError {
    
    // MARK: - Network Errors
    case networkError(underlying: Error)
    case invalidURL
    case invalidResponse(statusCode: Int)
    case noData
    case requestTimeout
    
    // MARK: - Parsing Errors
    case parsingError(underlying: Error)
    case invalidRSSFormat
    
    // MARK: - Database Errors
    case databaseError(underlying: Error)
    case databaseInitializationFailed
    case objectNotFound
    case objectInvalidated
    
    // MARK: - General Errors
    case unknown(underlying: Error?)
    
    // MARK: - LocalizedError
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidURL:
            return "Invalid URL provided"
        case .invalidResponse(let statusCode):
            return "Server returned error: \(statusCode)"
        case .noData:
            return "No data received from server"
        case .requestTimeout:
            return "Request timed out"
        case .parsingError(let error):
            return "Failed to parse data: \(error.localizedDescription)"
        case .invalidRSSFormat:
            return "Invalid RSS feed format"
        case .databaseError(let error):
            return "Database error: \(error.localizedDescription)"
        case .databaseInitializationFailed:
            return "Failed to initialize database"
        case .objectNotFound:
            return "Requested object not found"
        case .objectInvalidated:
            return "Object has been invalidated"
        case .unknown(let error):
            if let error = error {
                return "Unknown error: \(error.localizedDescription)"
            }
            return "Unknown error occurred"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .networkError:
            return "The network request failed"
        case .invalidURL:
            return "The URL could not be parsed"
        case .invalidResponse:
            return "The server response was invalid"
        case .noData:
            return "The server returned no data"
        case .requestTimeout:
            return "The request took too long"
        case .parsingError, .invalidRSSFormat:
            return "The data format is incorrect"
        case .databaseError, .databaseInitializationFailed:
            return "Database operation failed"
        case .objectNotFound, .objectInvalidated:
            return "The requested data is unavailable"
        case .unknown:
            return "An unexpected error occurred"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError, .requestTimeout:
            return "Please check your internet connection and try again"
        case .invalidURL, .invalidResponse, .noData:
            return "Please try again later"
        case .parsingError, .invalidRSSFormat:
            return "The news source may be temporarily unavailable"
        case .databaseError, .databaseInitializationFailed:
            return "Try clearing the app cache in Settings"
        case .objectNotFound, .objectInvalidated:
            return "Please refresh the content"
        case .unknown:
            return "Please try again"
        }
    }
    
    var alertTitle: String {
        switch self {
        case .networkError, .invalidURL, .invalidResponse, .noData, .requestTimeout:
            return "Network Error"
        case .parsingError, .invalidRSSFormat:
            return "Content Error"
        case .databaseError, .databaseInitializationFailed, .objectNotFound, .objectInvalidated:
            return "Data Error"
        case .unknown:
            return "Error"
        }
    }
    
    var userMessage: String {
        guard let description = errorDescription else {
            return "An error occurred. Please try again."
        }
        
        if let suggestion = recoverySuggestion {
            return "\(description)\n\n\(suggestion)"
        }
        
        return description
    }
    
}

// MARK: - Equatable for testing
extension AppError: Equatable {
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
            (.noData, .noData),
            (.requestTimeout, .requestTimeout),
            (.invalidRSSFormat, .invalidRSSFormat),
            (.databaseInitializationFailed, .databaseInitializationFailed),
            (.objectNotFound, .objectNotFound),
            (.objectInvalidated, .objectInvalidated):
            return true
        case (.invalidResponse(let lhsCode), .invalidResponse(let rhsCode)):
            return lhsCode == rhsCode
        case (.networkError, .networkError),
            (.parsingError, .parsingError),
            (.databaseError, .databaseError),
            (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
    
}
