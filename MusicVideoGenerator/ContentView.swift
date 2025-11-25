import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ProjectViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                switch viewModel.currentStep {
                case .upload:
                    UploadView(viewModel: viewModel)
                case .analyzing:
                    AnalysisView(viewModel: viewModel)
                case .generating:
                    GeneratingView(viewModel: viewModel)
                case .editing:
                    EditorView(viewModel: viewModel)
                case .exporting:
                    ExportingView(viewModel: viewModel)
                case .completed:
                    CompletedView(viewModel: viewModel)
                }
            }
            .navigationTitle("Music Video Generator")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
