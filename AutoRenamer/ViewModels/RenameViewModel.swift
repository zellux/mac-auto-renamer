import Foundation
import SwiftUI
import Combine

class RenameViewModel: ObservableObject {
    @Published var files: [FileItem] = []
    @Published var templateString: String = "{date}_{topic}.{ext}"
    @Published var selectedProvider: LLMProvider = .openAI
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var totalTokenUsage = TokenUsage(input: 0, output: 0)

    var template: RenameTemplate {
        RenameTemplate(templateString: templateString)
    }

    var hasFiles: Bool { !files.isEmpty }
    var hasReadyFiles: Bool { files.contains { $0.status == .ready && $0.isSelected } }

    // MARK: - Drop Handling

    func addFiles(urls: [URL]) {
        // If all existing files are already renamed, clear the list for the new batch
        if !files.isEmpty && files.allSatisfy({ $0.status == .renamed }) {
            files.removeAll()
            errorMessage = nil
            totalTokenUsage = TokenUsage(input: 0, output: 0)
        }

        for url in urls {
            guard !files.contains(where: { $0.originalURL.path == url.path }) else { continue }
            let item = FileItem(originalURL: url, originalName: url.lastPathComponent)
            files.append(item)
        }
    }

    func removeFile(at index: Int) {
        files.remove(at: index)
    }

    func clearFiles() {
        files.removeAll()
        errorMessage = nil
        totalTokenUsage = TokenUsage(input: 0, output: 0)
    }

    // MARK: - Processing

    func processFiles() async {
        guard !isProcessing else { return }

        let apiKey = KeychainHelper.load(key: selectedProvider.keychainKey)
        guard let apiKey, !apiKey.isEmpty else {
            errorMessage = "No API key configured for \(selectedProvider.displayName). Please set it in Settings (⌘,)."
            return
        }

        let service: any LLMService = switch selectedProvider {
        case .openAI: OpenAIService(apiKey: apiKey)
        case .anthropic: AnthropicService(apiKey: apiKey)
        }

        isProcessing = true
        errorMessage = nil

        // Process files sequentially to avoid rate limits
        for i in files.indices {
            guard files[i].status == .pending || files[i].status != .ready else { continue }
            files[i].status = .processing

            do {
                let content = try FileContentExtractor.extract(from: files[i].originalURL)
                let result = try await service.analyzeFile(
                    content: content,
                    template: template,
                    fileName: files[i].originalName
                )

                // Add file extension to the values so templates can use {ext}
                var allValues = result.values
                allValues["ext"] = files[i].fileExtension

                let proposed = template.apply(values: allValues)
                files[i].proposedName = proposed
                files[i].tokenUsage = result.tokenUsage
                files[i].status = .ready

                totalTokenUsage = TokenUsage(
                    input: totalTokenUsage.input + result.tokenUsage.input,
                    output: totalTokenUsage.output + result.tokenUsage.output
                )
            } catch {
                files[i].status = .error(error.localizedDescription)
            }
        }

        isProcessing = false
    }

    // MARK: - Renaming

    func confirmRename() async {
        var errors: [String] = []

        for i in files.indices {
            guard files[i].isSelected,
                  files[i].status == .ready,
                  let proposedName = files[i].proposedName else { continue }

            let directory = files[i].originalURL.deletingLastPathComponent()
            let newURL = directory.appendingPathComponent(proposedName)

            do {
                try FileManager.default.moveItem(at: files[i].originalURL, to: newURL)
                files[i].status = .renamed
            } catch {
                let msg = error.localizedDescription
                files[i].status = .error(msg)
                errors.append("\(files[i].originalName): \(msg)")
            }
        }

        if !errors.isEmpty {
            errorMessage = errors.joined(separator: "\n")
        }
    }
}
