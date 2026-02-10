import SwiftUI

struct FileRowView: View {
    @Binding var item: FileItem

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: $item.isSelected)
                .labelsHidden()
                .disabled(item.status != .ready)

            Image(nsImage: NSWorkspace.shared.icon(forFileType: item.fileExtension))
                .resizable()
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.originalName)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .strikethrough(item.status == .renamed)

                if let proposed = item.proposedName {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        if item.status == .renamed {
                            Text(proposed)
                                .font(.body.weight(.medium))
                        } else {
                            TextField("Proposed name", text: Binding(
                                get: { proposed },
                                set: { item.proposedName = $0 }
                            ))
                            .textFieldStyle(.plain)
                            .font(.body.weight(.medium))
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }

            Spacer()

            if let usage = item.tokenUsage {
                Text("\(usage.total) tokens")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .help("Input: \(usage.input), Output: \(usage.output)")
            }

            statusView
        }
        .padding(.vertical, 4)
        .opacity(item.status == .renamed ? 0.6 : 1.0)
    }

    @ViewBuilder
    private var statusView: some View {
        switch item.status {
        case .pending:
            Image(systemName: "clock")
                .foregroundStyle(.secondary)
        case .processing:
            ProgressView()
                .scaleEffect(0.7)
        case .ready:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        case .renamed:
            Label("Renamed", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        case .error(let message):
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .help(message)
        }
    }
}
