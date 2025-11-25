import SwiftUI

struct AnalysisView: View {
    @ObservedObject var viewModel: ProjectViewModel

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            ProgressView(value: viewModel.progress) {
                Text("Analyzing Audio...")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            .progressViewStyle(.linear)
            .padding(.horizontal, 40)

            VStack(spacing: 15) {
                AnalysisStepView(
                    title: "Extracting Audio Features",
                    isComplete: viewModel.progress > 0.3,
                    isActive: viewModel.progress <= 0.5
                )

                AnalysisStepView(
                    title: "Transcribing Lyrics",
                    isComplete: viewModel.progress > 0.7,
                    isActive: viewModel.progress > 0.5 && viewModel.progress <= 0.7
                )

                AnalysisStepView(
                    title: "Identifying Themes",
                    isComplete: viewModel.progress >= 1.0,
                    isActive: viewModel.progress > 0.7
                )
            }
            .padding()

            if let song = viewModel.project?.song,
               let analysis = song.analysis {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Analysis Results")
                        .font(.headline)

                    HStack {
                        Label("Tempo: \(Int(analysis.tempo)) BPM", systemImage: "metronome")
                        Spacer()
                    }

                    HStack {
                        Label("Energy: \(Int(analysis.energy * 100))%", systemImage: "bolt.fill")
                        Spacer()
                    }

                    HStack {
                        Label("Mood: \(analysis.mood.rawValue.capitalized)", systemImage: "face.smiling")
                        Spacer()
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }

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

struct AnalysisStepView: View {
    let title: String
    let isComplete: Bool
    let isActive: Bool

    var body: some View {
        HStack {
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else if isActive {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "circle")
                    .foregroundColor(.gray)
            }

            Text(title)
                .foregroundColor(isActive ? .primary : .secondary)

            Spacer()
        }
        .padding(.horizontal)
    }
}
