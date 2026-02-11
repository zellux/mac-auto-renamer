# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AutoRenamer is a macOS application built with SwiftUI (deployment target macOS 26.2). Users drag-and-drop files, provide a naming template (e.g., `{date}_{topic}_{author}.pdf`), and an LLM (OpenAI or Anthropic) analyzes file content to propose new names. Users review and confirm before renaming.

The project uses an Xcode-based build system (no Swift Package Manager or third-party dependencies).

## Build Commands

```bash
# Build (debug)
xcodebuild -project AutoRenamer.xcodeproj -scheme AutoRenamer -configuration Debug build

# Build (release)
xcodebuild -project AutoRenamer.xcodeproj -scheme AutoRenamer -configuration Release build

# Clean
xcodebuild -project AutoRenamer.xcodeproj -scheme AutoRenamer clean
```

No test targets, linting tools, or CI/CD pipelines are currently configured.

## Architecture

```
AutoRenamer/
├── AutoRenamerApp.swift          — @main entry point, WindowGroup + Settings scenes
├── ContentView.swift             — Main UI: template field, file list, action buttons
├── Models/
│   ├── FileItem.swift            — File tracking struct (URL, status, proposed name, token usage)
│   ├── RenameTemplate.swift      — Parses "{var}" templates and substitutes values
│   └── LLMProvider.swift         — Enum: .openAI, .anthropic with base URLs and display names
├── Services/
│   ├── LLMService.swift          — Protocol + OpenAI (GPT-4o) and Anthropic (Claude) implementations
│   ├── FileContentExtractor.swift — Extracts text (PDFKit) or image data from files
│   └── KeychainHelper.swift      — API key storage via UserDefaults
├── ViewModels/
│   └── RenameViewModel.swift     — Main orchestrator: file list, LLM calls, renaming
└── Views/
    ├── DropZoneView.swift        — Drag-and-drop target with visual feedback
    ├── FileDropOverlay.swift     — NSViewRepresentable for AppKit-level drag-and-drop
    ├── FileListView.swift        — List of files with delete support
    ├── FileRowView.swift         — Single file row: checkbox, names, status, token count
    └── SettingsView.swift        — API key + provider configuration
```

## Key Technical Notes

- **No sandbox**: App Sandbox is disabled (`ENABLE_APP_SANDBOX = NO`) because `FileManager.moveItem` requires directory-level write access that the sandbox doesn't grant for drag-and-dropped files.
- **AppKit drag-and-drop**: Uses `NSViewRepresentable` (`FileDropOverlay`) instead of SwiftUI's `onDrop`/`dropDestination` to get proper file URLs from `NSDraggingInfo.draggingPasteboard`.
- **Concurrency**: Project has `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` and `SWIFT_APPROACHABLE_CONCURRENCY = YES`. Services use `nonisolated` for async work.
- **No macros**: `@Observable` and `#Preview` macros don't work with the CLI `xcodebuild` in this environment. Uses `ObservableObject`/`@Published` instead.
- **API keys**: Stored in `UserDefaults` (not Keychain) to avoid permission prompts.
- **No third-party dependencies**: Uses `URLSession` for API calls, `PDFKit` for PDFs, Security framework APIs replaced by UserDefaults.
