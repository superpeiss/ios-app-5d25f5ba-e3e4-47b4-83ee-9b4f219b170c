import SwiftUI

struct ExportingView: View {
    @ObservedObject var viewModel: ProjectViewModel

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            ProgressView(value: viewModel.progress) {
                Text("Exporting Video")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .progressViewStyle(.linear)
            .padding(.horizontal, 40)

            VStack(spacing: 10) {
                Text("\(Int(viewModel.progress * 100))% Complete")
                    .font(.headline)

                Text("This may take a few minutes...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Image(systemName: "film")
                .font(.system(size: 80))
                .foregroundColor(.blue)
                .padding()

            Spacer()

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
        }
        .padding()
    }
}
