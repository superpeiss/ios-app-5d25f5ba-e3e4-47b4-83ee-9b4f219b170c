import SwiftUI

struct GeneratingView: View {
    @ObservedObject var viewModel: ProjectViewModel

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            ProgressView(value: viewModel.progress) {
                Text("Generating Video")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .progressViewStyle(.linear)
            .padding(.horizontal, 40)

            VStack(spacing: 15) {
                Text("Fetching visual content...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let lyrics = viewModel.project?.song.lyrics {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Keywords:")
                            .font(.caption)
                            .fontWeight(.semibold)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(lyrics.keywords.prefix(10), id: \.self) { keyword in
                                    Text(keyword)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(15)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }

            Spacer()

            if viewModel.progress >= 1.0 {
                Button(action: {
                    // Already moved to editing automatically
                }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Continue to Editor")
                    }
                    .padding()
                    .frame(maxWidth: 300)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }
}
