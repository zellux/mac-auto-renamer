import Foundation

struct TokenUsage {
    var input: Int
    var output: Int
    var total: Int { input + output }
}

struct FileItem: Identifiable {
    let id = UUID()
    let originalURL: URL
    let originalName: String
    var proposedName: String?
    var status: Status = .pending
    var isSelected: Bool = true
    var tokenUsage: TokenUsage?

    enum Status: Equatable {
        case pending
        case processing
        case ready
        case renamed
        case error(String)
    }

    var fileExtension: String {
        originalURL.pathExtension
    }
}
