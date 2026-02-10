# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AutoRenamer is a macOS application built with SwiftUI (deployment target macOS 26.2). The project uses an Xcode-based build system (no Swift Package Manager).

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

Standard SwiftUI app structure:

- **AutoRenamerApp.swift** — `@main` entry point with a single `WindowGroup` scene
- **ContentView.swift** — Root view (currently placeholder)
- **Assets.xcassets/** — Asset catalog (app icon, accent color)

The app has App Sandbox enabled with read-only user-selected file access.
