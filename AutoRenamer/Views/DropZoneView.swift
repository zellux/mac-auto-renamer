import SwiftUI

struct DropZoneView: View {
    @Binding var isTargeted: Bool
    var onDrop: ([URL]) -> Void

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Drop files here")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("PDF, images, text files")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                )
                .foregroundStyle(isTargeted ? Color.accentColor : Color.secondary.opacity(0.5))
        }
        .background {
            if isTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.05))
            }
        }
        .overlay {
            FileDropOverlay(onDrop: onDrop, isTargeted: $isTargeted)
        }
    }
}
