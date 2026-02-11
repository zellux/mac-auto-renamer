# AutoRenamer

A macOS app that uses LLMs to automatically rename files based on their content.

![screenshot](screenshot.png)

## How It Works

1. **Set up an API key** — Open Settings (Cmd+,) and enter your OpenAI or Anthropic API key.
2. **Define a template** — Write a naming pattern using `{variables}`, e.g. `{date}_{topic}_{author}.pdf`.
3. **Drop files** — Drag and drop PDFs, images, or text files onto the app.
4. **Analyze** — Click "Analyze" to have the LLM read each file and propose names based on your template.
5. **Review and rename** — Edit any proposed names, uncheck files you want to skip, then click "Rename".

## Templates

Templates use `{variable}` placeholders that the LLM fills in by analyzing file content. Use `{ext}` for the original file extension.

Examples:
- `{date}_{topic}.{ext}` → `2024-03-15_quarterly_report.pdf`
- `{author}_{title}.{ext}` → `john_smith_invoice.pdf`
- `{date}_{category}_{description}.{ext}` → `2024-01_receipt_office_supplies.jpg`

You can use any variable names — the LLM will interpret them based on the file content.

## Supported File Types

- **PDF** — Text is extracted; falls back to image analysis for scanned documents
- **Images** — PNG, JPG, GIF, WebP, HEIC (analyzed via vision API)
- **Text** — TXT, MD, CSV, JSON, and other plain text formats

## Supported Providers

- **OpenAI** — Uses GPT-4o
- **Anthropic** — Uses Claude Sonnet

## Installation

Download the latest build from [Releases](releases/), unzip, and move to your Applications folder.

Or build from source:

```bash
xcodebuild -project AutoRenamer.xcodeproj -scheme AutoRenamer -configuration Release build
```

Requires macOS 26.2+ and Xcode 26+.
