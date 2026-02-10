import AppKit
import SwiftUI

struct FileDropOverlay: NSViewRepresentable {
    var onDrop: ([URL]) -> Void
    @Binding var isTargeted: Bool

    func makeNSView(context: Context) -> DropReceivingView {
        let view = DropReceivingView()
        view.onDrop = onDrop
        view.onTargetChanged = { isTargeted = $0 }
        view.registerForDraggedTypes([.fileURL])
        return view
    }

    func updateNSView(_ nsView: DropReceivingView, context: Context) {
        nsView.onDrop = onDrop
        nsView.onTargetChanged = { isTargeted = $0 }
    }

    class DropReceivingView: NSView {
        var onDrop: (([URL]) -> Void)?
        var onTargetChanged: ((Bool) -> Void)?

        override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
            DispatchQueue.main.async { self.onTargetChanged?(true) }
            return .copy
        }

        override func draggingExited(_ sender: NSDraggingInfo?) {
            DispatchQueue.main.async { self.onTargetChanged?(false) }
        }

        override func draggingEnded(_ sender: NSDraggingInfo) {
            DispatchQueue.main.async { self.onTargetChanged?(false) }
        }

        override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
            true
        }

        override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
            guard let urls = sender.draggingPasteboard.readObjects(
                forClasses: [NSURL.self],
                options: [.urlReadingFileURLsOnly: true]
            ) as? [URL], !urls.isEmpty else {
                return false
            }
            DispatchQueue.main.async { self.onDrop?(urls) }
            return true
        }
    }
}
