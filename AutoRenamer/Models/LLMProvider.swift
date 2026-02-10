import Foundation

enum LLMProvider: String, CaseIterable, Identifiable, Codable {
    case openAI
    case anthropic

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .openAI: "OpenAI"
        case .anthropic: "Anthropic"
        }
    }

    var baseURL: URL {
        switch self {
        case .openAI: URL(string: "https://api.openai.com/v1")!
        case .anthropic: URL(string: "https://api.anthropic.com/v1")!
        }
    }

    var keychainKey: String {
        switch self {
        case .openAI: "openai_api_key"
        case .anthropic: "anthropic_api_key"
        }
    }
}
