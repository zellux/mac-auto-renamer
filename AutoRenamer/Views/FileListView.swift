import SwiftUI

struct FileListView: View {
    @Binding var files: [FileItem]

    var body: some View {
        List {
            ForEach($files) { $item in
                FileRowView(item: $item)
            }
            .onDelete { indexSet in
                files.remove(atOffsets: indexSet)
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }
}
