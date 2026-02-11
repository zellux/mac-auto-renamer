import SwiftUI

struct SettingsView: View {
    @State private var selectedProvider: LLMProvider = .openAI
    @State private var apiKey: String = ""
    @State private var modelName: String = ""
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
                loadModel()
                testStatus = nil
            }

            SecureField("API Key", text: $apiKey)
                .onChange(of: apiKey) {
                    testStatus = nil
                }

            TextField("Model", text: $modelName, prompt: Text(selectedProvider.defaultModel))
                .onChange(of: modelName) {
                    testStatus = nil
                }

            HStack {
                Button("Save") {
                    KeychainHelper.save(key: selectedProvider.keychainKey, value: apiKey)
                    UserDefaults.standard.set(modelName, forKey: selectedProvider.modelKey)
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
        .onAppear {
            loadKey()
            loadModel()
        }
    }

    private func loadKey() {
        apiKey = KeychainHelper.load(key: selectedProvider.keychainKey) ?? ""
    }

    private func loadModel() {
        modelName = UserDefaults.standard.string(forKey: selectedProvider.modelKey) ?? ""
    }

    private func testConnection() {
        testStatus = .testing
        let provider = selectedProvider
        let key = apiKey
        let model = modelName.isEmpty ? provider.defaultModel : modelName
        KeychainHelper.save(key: provider.keychainKey, value: key)
        UserDefaults.standard.set(modelName, forKey: provider.modelKey)

        Task {
            do {
                let service: any LLMService = switch provider {
                case .openAI: OpenAIService(apiKey: key, model: model)
                case .anthropic: AnthropicService(apiKey: key, model: model)
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
