import SwiftUI
import UniformTypeIdentifiers

struct UploadView: View {
    @ObservedObject var viewModel: ProjectViewModel
    @State private var showingFilePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var songTitle = ""

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "music.note")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            Text("Create Your Music Video")
                .font(.title)
                .fontWeight(.bold)

            Text("Upload an audio file to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: {
                showingFilePicker = true
            }) {
                HStack {
                    Image(systemName: "arrow.up.doc")
                    Text("Upload Audio File")
                }
                .padding()
                .frame(maxWidth: 300)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding()

            Spacer()

            Text("Supported formats: MP3, WAV, M4A")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .sheet(isPresented: $showingFilePicker) {
            DocumentPicker(songTitle: $songTitle) { url in
                handleAudioFile(url: url)
            }
        }
        .alert("Error", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func handleAudioFile(url: URL) {
        // Request speech recognition permission
        LyricsTranscriptionService.shared.requestAuthorization { authorized in
            if !authorized {
                alertMessage = "Speech recognition permission is required for lyrics transcription. You can still use the app without this feature."
                showingAlert = true
            }
        }

        // Create project
        let title = songTitle.isEmpty ? url.deletingPathExtension().lastPathComponent : songTitle
        viewModel.createProject(from: url, title: title)
    }
}

// MARK: - Document Picker

struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var songTitle: String
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [
            UTType.audio,
            UTType.mp3,
            UTType.mpeg4Audio
        ])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: DocumentPicker

        init(_ parent: DocumentPicker) {
            self.parent = parent
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }

            // Get access to the file
            guard url.startAccessingSecurityScopedResource() else {
                return
            }

            defer {
                url.stopAccessingSecurityScopedResource()
            }

            // Copy to temporary location
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(url.lastPathComponent)

            do {
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(at: tempURL)
                }
                try FileManager.default.copyItem(at: url, to: tempURL)
                parent.onPick(tempURL)
            } catch {
                print("Error copying file: \(error)")
            }
        }
    }
}
