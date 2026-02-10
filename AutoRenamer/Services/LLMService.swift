import Foundation

struct AnalysisResult: Sendable {
    let values: [String: String]
    let tokenUsage: TokenUsage
}

protocol LLMService: Sendable {
    func analyzeFile(content: FileContent, template: RenameTemplate, fileName: String) async throws -> AnalysisResult
}

enum LLMServiceError: LocalizedError {
    case noAPIKey
    case requestFailed(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noAPIKey: "No API key configured. Please set it in Settings."
        case .requestFailed(let message): "API request failed: \(message)"
        case .invalidResponse: "Could not parse API response."
        }
    }
}

// MARK: - OpenAI

struct OpenAIService: LLMService {
    let apiKey: String

    nonisolated func analyzeFile(content: FileContent, template: RenameTemplate, fileName: String) async throws -> AnalysisResult {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let variables = template.variableNames
        let prompt = buildPrompt(variables: variables, fileName: fileName)
        let messages = buildOpenAIMessages(prompt: prompt, content: content)

        let body: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "temperature": 0.1,
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMServiceError.requestFailed("No HTTP response")
        }
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LLMServiceError.requestFailed("HTTP \(httpResponse.statusCode): \(errorBody)")
        }

        return try parseOpenAIResponse(data: data)
    }

    nonisolated private func buildOpenAIMessages(prompt: String, content: FileContent) -> [[String: Any]] {
        switch content {
        case .text(let text):
            return [
                [
                    "role": "user",
                    "content": "\(prompt)\n\nFile content:\n\(String(text.prefix(8000)))"
                ]
            ]
        case .image(let data, let mimeType):
            let base64 = data.base64EncodedString()
            let mediaType = mimeType == "application/octet-stream" ? "image/png" : mimeType
            return [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": prompt],
                        ["type": "image_url", "image_url": ["url": "data:\(mediaType);base64,\(base64)"]]
                    ] as [[String: Any]]
                ]
            ]
        }
    }

    nonisolated private func parseOpenAIResponse(data: Data) throws -> AnalysisResult {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw LLMServiceError.invalidResponse
        }

        let usage: TokenUsage
        if let usageDict = json["usage"] as? [String: Any] {
            let input = usageDict["prompt_tokens"] as? Int ?? 0
            let output = usageDict["completion_tokens"] as? Int ?? 0
            usage = TokenUsage(input: input, output: output)
        } else {
            usage = TokenUsage(input: 0, output: 0)
        }

        let values = try extractJSON(from: text)
        return AnalysisResult(values: values, tokenUsage: usage)
    }
}

// MARK: - Anthropic

struct AnthropicService: LLMService {
    let apiKey: String

    nonisolated func analyzeFile(content: FileContent, template: RenameTemplate, fileName: String) async throws -> AnalysisResult {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.addValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let variables = template.variableNames
        let prompt = buildPrompt(variables: variables, fileName: fileName)
        let messageContent = buildAnthropicContent(prompt: prompt, content: content)

        let body: [String: Any] = [
            "model": "claude-sonnet-4-20250514",
            "max_tokens": 1024,
            "messages": [
                ["role": "user", "content": messageContent]
            ],
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMServiceError.requestFailed("No HTTP response")
        }
        guard httpResponse.statusCode == 200 else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LLMServiceError.requestFailed("HTTP \(httpResponse.statusCode): \(errorBody)")
        }

        return try parseAnthropicResponse(data: data)
    }

    nonisolated private func buildAnthropicContent(prompt: String, content: FileContent) -> Any {
        switch content {
        case .text(let text):
            return "\(prompt)\n\nFile content:\n\(String(text.prefix(8000)))"
        case .image(let data, let mimeType):
            let base64 = data.base64EncodedString()
            let mediaType = mimeType == "application/octet-stream" ? "image/png" : mimeType
            return [
                ["type": "text", "text": prompt],
                ["type": "image", "source": [
                    "type": "base64",
                    "media_type": mediaType,
                    "data": base64
                ]]
            ] as [[String: Any]]
        }
    }

    nonisolated private func parseAnthropicResponse(data: Data) throws -> AnalysisResult {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let contentArray = json["content"] as? [[String: Any]],
              let first = contentArray.first,
              let text = first["text"] as? String else {
            throw LLMServiceError.invalidResponse
        }

        let usage: TokenUsage
        if let usageDict = json["usage"] as? [String: Any] {
            let input = usageDict["input_tokens"] as? Int ?? 0
            let output = usageDict["output_tokens"] as? Int ?? 0
            usage = TokenUsage(input: input, output: output)
        } else {
            usage = TokenUsage(input: 0, output: 0)
        }

        let values = try extractJSON(from: text)
        return AnalysisResult(values: values, tokenUsage: usage)
    }
}

// MARK: - Shared Helpers

private func buildPrompt(variables: [String], fileName: String) -> String {
    let variableList = variables.joined(separator: ", ")
    return """
    Analyze this file and extract values for a file naming template. \
    The original file name is "\(fileName)".

    Extract values for these template variables: \(variableList)

    Rules:
    - Use only filesystem-safe characters (no / \\ : * ? " < > |)
    - Use hyphens or underscores instead of spaces
    - Keep values concise (1-4 words each)
    - For dates, use YYYY-MM-DD format
    - If a value cannot be determined, use "unknown"

    Respond ONLY with a JSON object mapping variable names to extracted values. \
    Example: {"date": "2024-01-15", "topic": "quarterly-report", "author": "john-smith"}
    """
}

private func extractJSON(from text: String) throws -> [String: String] {
    // Try to find JSON in the response (might be wrapped in markdown code blocks)
    let cleaned: String
    if let jsonStart = text.firstIndex(of: "{"),
       let jsonEnd = text.lastIndex(of: "}") {
        cleaned = String(text[jsonStart...jsonEnd])
    } else {
        cleaned = text
    }

    guard let data = cleaned.data(using: .utf8),
          let dict = try JSONSerialization.jsonObject(with: data) as? [String: String] else {
        throw LLMServiceError.invalidResponse
    }
    return dict
}
