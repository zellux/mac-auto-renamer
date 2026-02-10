import SwiftUI

struct SettingsView: View {
    @State private var selectedProvider: LLMProvider = .openAI
    @State private var apiKey: String = ""
    @State private var testStatus: TestStatus?

    enum TestStatus: Equatable {
        case testing
        case success
        case failure(String)
    }

    var body: some View {
        Form {
            Picker("LLM Provider", selection: $selectedProvider) {
                ForEach(LLMProvider.allCases) { provider in
                    Text(provider.displayName).tag(provider)
                }
            }
            .onChange(of: selectedProvider) {
                loadKey()
                testStatus = nil
            }

            SecureField("API Key", text: $apiKey)
                .onChange(of: apiKey) {
                    testStatus = nil
                }

            HStack {
                Button("Save") {
                    KeychainHelper.save(key: selectedProvider.keychainKey, value: apiKey)
                }

                Button("Test Connection") {
                    testConnection()
                }
                .disabled(apiKey.isEmpty)

                if let testStatus {
                    switch testStatus {
                    case .testing:
                        ProgressView()
                            .scaleEffect(0.7)
                    case .success:
                        Label("Connected", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    case .failure(let msg):
                        Label(msg, systemImage: "xmark.circle.fill")
                            .foregroundStyle(.red)
                            .lineLimit(2)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450)
        .onAppear { loadKey() }
    }

    private func loadKey() {
        apiKey = KeychainHelper.load(key: selectedProvider.keychainKey) ?? ""
    }

    private func testConnection() {
        testStatus = .testing
        let provider = selectedProvider
        let key = apiKey
        KeychainHelper.save(key: provider.keychainKey, value: key)

        Task {
            do {
                let service: any LLMService = switch provider {
                case .openAI: OpenAIService(apiKey: key)
                case .anthropic: AnthropicService(apiKey: key)
                }

                let testTemplate = RenameTemplate(templateString: "{test}")
                _ = try await service.analyzeFile(
                    content: .text("Hello, this is a test."),
                    template: testTemplate,
                    fileName: "test.txt"
                )
                testStatus = .success
            } catch {
                testStatus = .failure(error.localizedDescription)
            }
        }
    }
}
