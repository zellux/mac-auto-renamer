import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = RenameViewModel()
    @State private var isDropTargeted = false

    private func hasAPIKey(_ provider: LLMProvider) -> Bool {
        let key = KeychainHelper.load(key: provider.keychainKey)
        return key != nil && !key!.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Template field
            HStack {
                Text("Template:")
                    .font(.headline)
                TextField("e.g. {date}_{topic}_{author}.pdf", text: $viewModel.templateString)
                    .textFieldStyle(.roundedBorder)
                Menu {
                    Section("Documents") {
                        Button("{date}_{topic}.{ext}") { viewModel.templateString = "{date}_{topic}.{ext}" }
                        Button("{date}_{author}_{title}.{ext}") { viewModel.templateString = "{date}_{author}_{title}.{ext}" }
                        Button("{category}_{title}.{ext}") { viewModel.templateString = "{category}_{title}.{ext}" }
                    }
                    Section("Receipts / Invoices") {
                        Button("{date}_{vendor}_{amount}.{ext}") { viewModel.templateString = "{date}_{vendor}_{amount}.{ext}" }
                        Button("{date}_{invoice_number}.{ext}") { viewModel.templateString = "{date}_{invoice_number}.{ext}" }
                        Button("{date}_{vendor}_{project}.{ext}") { viewModel.templateString = "{date}_{vendor}_{project}.{ext}" }
                    }
                    Section("Photos") {
                        Button("{date}_{location}_{subject}.{ext}") { viewModel.templateString = "{date}_{location}_{subject}.{ext}" }
                        Button("{date}_{event}.{ext}") { viewModel.templateString = "{date}_{event}.{ext}" }
                    }
                } label: {
                    Image(systemName: "list.bullet")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding()

            Divider()

            // Main content area
            if viewModel.hasFiles {
                FileListView(files: $viewModel.files)
                    .overlay {
                        FileDropOverlay(onDrop: { urls in
                            viewModel.addFiles(urls: urls)
                        }, isTargeted: $isDropTargeted)
                    }
            } else {
                DropZoneView(isTargeted: $isDropTargeted) { urls in
                    viewModel.addFiles(urls: urls)
                }
                .padding()
            }

            // Error message
            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }

            Divider()

            // Action buttons
            HStack {
                Picker("Provider", selection: $viewModel.selectedProvider) {
                    ForEach(LLMProvider.allCases) { provider in
                        if hasAPIKey(provider) {
                            Text(provider.displayName).tag(provider)
                        } else {
                            Text("\(provider.displayName) (no key)").tag(provider)
                        }
                    }
                }
                .frame(width: 200)

                if !hasAPIKey(viewModel.selectedProvider) {
                    Text("Set API key in Settings (⌘,)")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Spacer()

                if viewModel.totalTokenUsage.total > 0 {
                    Text("Tokens: \(viewModel.totalTokenUsage.total)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .help("Input: \(viewModel.totalTokenUsage.input), Output: \(viewModel.totalTokenUsage.output)")
                }

                if viewModel.isProcessing {
                    ProgressView()
                        .scaleEffect(0.8)
                        .padding(.trailing, 4)
                }

                Button("Clear") {
                    viewModel.clearFiles()
                }
                .disabled(viewModel.files.isEmpty)

                Button("Analyze") {
                    Task { await viewModel.processFiles() }
                }
                .disabled(viewModel.files.isEmpty || viewModel.isProcessing || !hasAPIKey(viewModel.selectedProvider))

                Button("Rename") {
                    Task { await viewModel.confirmRename() }
                }
                .disabled(!viewModel.hasReadyFiles || viewModel.isProcessing)
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(minWidth: 600, minHeight: 400)
    }
}
