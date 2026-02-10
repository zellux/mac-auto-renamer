import Foundation
import PDFKit
import AppKit

enum FileContent: Sendable {
    case text(String)
    case image(Data, mimeType: String)
}

enum FileContentExtractor {
    nonisolated static func extract(from url: URL) throws -> FileContent {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "pdf":
            return try extractPDF(from: url)
        case "png":
            return try .image(Data(contentsOf: url), mimeType: "image/png")
        case "jpg", "jpeg":
            return try .image(Data(contentsOf: url), mimeType: "image/jpeg")
        case "gif":
            return try .image(Data(contentsOf: url), mimeType: "image/gif")
        case "webp":
            return try .image(Data(contentsOf: url), mimeType: "image/webp")
        case "heic", "heif":
            return try extractHEIC(from: url)
        case "txt", "md", "csv", "json", "xml", "html", "swift", "py", "js", "ts":
            let text = try String(contentsOf: url, encoding: .utf8)
            return .text(text)
        default:
            // Try reading as text first, fall back to treating as image
            if let text = try? String(contentsOf: url, encoding: .utf8), !text.isEmpty {
                return .text(text)
            }
            let data = try Data(contentsOf: url)
            return .image(data, mimeType: "application/octet-stream")
        }
    }

    nonisolated private static func extractPDF(from url: URL) throws -> FileContent {
        guard let document = PDFDocument(url: url) else {
            throw ExtractionError.cannotOpenPDF
        }

        var text = ""
        for i in 0..<min(document.pageCount, 10) {
            if let page = document.page(at: i), let pageText = page.string {
                text += pageText + "\n"
            }
        }

        // If we got meaningful text, use it
        if text.trimmingCharacters(in: .whitespacesAndNewlines).count > 50 {
            return .text(text)
        }

        // Otherwise render first page as image
        if let page = document.page(at: 0) {
            let bounds = page.bounds(for: .mediaBox)
            let scale: CGFloat = 2.0
            let size = NSSize(width: bounds.width * scale, height: bounds.height * scale)
            let image = NSImage(size: size)
            image.lockFocus()
            if let context = NSGraphicsContext.current?.cgContext {
                context.scaleBy(x: scale, y: scale)
                page.draw(with: .mediaBox, to: context)
            }
            image.unlockFocus()

            if let tiff = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiff),
               let png = bitmap.representation(using: .png, properties: [:]) {
                return .image(png, mimeType: "image/png")
            }
        }

        return .text(text)
    }

    nonisolated private static func extractHEIC(from url: URL) throws -> FileContent {
        let data = try Data(contentsOf: url)
        guard let image = NSImage(data: data),
              let tiff = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            return .image(data, mimeType: "image/heic")
        }
        return .image(png, mimeType: "image/png")
    }

    enum ExtractionError: LocalizedError {
        case cannotOpenPDF

        var errorDescription: String? {
            switch self {
            case .cannotOpenPDF: "Could not open PDF file."
            }
        }
    }
}
