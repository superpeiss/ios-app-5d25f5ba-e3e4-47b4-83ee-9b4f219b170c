import SwiftUI
import Photos

struct CompletedView: View {
    @ObservedObject var viewModel: ProjectViewModel
    @State private var showingSaveAlert = false
    @State private var saveMessage = ""

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)

            Text("Video Complete!")
                .font(.title)
                .fontWeight(.bold)

            if let exportURL = viewModel.project?.exportURL {
                Text("Saved to: \(exportURL.lastPathComponent)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding()

                VStack(spacing: 15) {
                    Button(action: {
                        saveToPhotoLibrary(url: exportURL)
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("Save to Photos")
                        }
                        .padding()
                        .frame(maxWidth: 300)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    Button(action: {
                        shareVideo(url: exportURL)
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share Video")
                        }
                        .padding()
                        .frame(maxWidth: 300)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }

            Spacer()

            Button(action: {
                viewModel.reset()
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Create Another Video")
                }
                .padding()
                .frame(maxWidth: 300)
                .background(Color.secondary.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(10)
            }
        }
        .padding()
        .alert("Save Result", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(saveMessage)
        }
    }

    private func saveToPhotoLibrary(url: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
                DispatchQueue.main.async {
                    saveMessage = "Photo library access denied"
                    showingSaveAlert = true
                }
                return
            }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        saveMessage = "Video saved to Photos successfully!"
                    } else {
                        saveMessage = "Failed to save video: \(error?.localizedDescription ?? "Unknown error")"
                    }
                    showingSaveAlert = true
                }
            }
        }
    }

    private func shareVideo(url: URL) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
