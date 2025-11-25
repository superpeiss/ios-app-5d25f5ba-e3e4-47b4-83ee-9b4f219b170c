import SwiftUI
import AVKit

struct EditorView: View {
    @ObservedObject var viewModel: ProjectViewModel
    @State private var selectedClip: VideoClip?
    @State private var showingColorGrading = false

    var body: some View {
        VStack(spacing: 0) {
            // Preview area
            if let project = viewModel.project {
                PreviewPlayer(clips: project.clips)
                    .frame(height: 250)
                    .background(Color.black)
            }

            // Timeline
            ScrollView(.horizontal, showsIndicators: true) {
                HStack(spacing: 2) {
                    if let clips = viewModel.project?.clips {
                        ForEach(clips) { clip in
                            ClipThumbnailView(clip: clip, isSelected: selectedClip?.id == clip.id)
                                .onTapGesture {
                                    selectedClip = clip
                                }
                        }
                    }
                }
                .padding()
            }
            .frame(height: 120)
            .background(Color.secondary.opacity(0.1))

            // Controls
            VStack(spacing: 15) {
                if let clip = selectedClip {
                    ClipControlsView(clip: clip, onUpdate: { updatedClip in
                        viewModel.updateClip(updatedClip)
                        selectedClip = updatedClip
                    }, onRemove: {
                        viewModel.removeClip(clip)
                        selectedClip = nil
                    })
                } else {
                    Text("Select a clip to edit")
                        .foregroundColor(.secondary)
                        .padding()
                }

                Divider()

                // Color Grading
                Button(action: {
                    showingColorGrading.toggle()
                }) {
                    HStack {
                        Image(systemName: "paintpalette")
                        Text("Color Grading")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                if showingColorGrading, let grading = viewModel.project?.colorGrading {
                    ColorGradingView(grading: grading) { updatedGrading in
                        viewModel.updateColorGrading(updatedGrading)
                    }
                }

                // Export Button
                Button(action: {
                    viewModel.exportVideo { result in
                        switch result {
                        case .success:
                            print("Export successful")
                        case .failure(let error):
                            print("Export failed: \(error)")
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Export Video")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }

            Spacer()
        }
    }
}

struct ClipThumbnailView: View {
    let clip: VideoClip
    let isSelected: Bool

    var body: some View {
        VStack {
            Rectangle()
                .fill(Color.gray)
                .frame(width: 100, height: 60)
                .overlay(
                    Image(systemName: "video.fill")
                        .foregroundColor(.white)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                )

            Text("\(Int(clip.duration))s")
                .font(.caption2)
        }
        .frame(width: 100)
    }
}

struct ClipControlsView: View {
    let clip: VideoClip
    let onUpdate: (VideoClip) -> Void
    let onRemove: () -> Void

    @State private var trimStart: Double
    @State private var trimEnd: Double

    init(clip: VideoClip, onUpdate: @escaping (VideoClip) -> Void, onRemove: @escaping () -> Void) {
        self.clip = clip
        self.onUpdate = onUpdate
        self.onRemove = onRemove
        _trimStart = State(initialValue: clip.trimStart)
        _trimEnd = State(initialValue: clip.trimEnd)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Clip Duration: \(String(format: "%.1f", clip.duration))s")
                .font(.caption)

            VStack(alignment: .leading) {
                Text("Trim Start: \(String(format: "%.1f", trimStart))s")
                    .font(.caption)
                Slider(value: $trimStart, in: 0...clip.duration, step: 0.1)
                    .onChange(of: trimStart) { _ in
                        updateClip()
                    }
            }

            VStack(alignment: .leading) {
                Text("Trim End: \(String(format: "%.1f", trimEnd))s")
                    .font(.caption)
                Slider(value: $trimEnd, in: 0...clip.duration, step: 0.1)
                    .onChange(of: trimEnd) { _ in
                        updateClip()
                    }
            }

            Button(action: onRemove) {
                HStack {
                    Image(systemName: "trash")
                    Text("Remove Clip")
                }
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private func updateClip() {
        var updatedClip = clip
        updatedClip.trimStart = trimStart
        updatedClip.trimEnd = trimEnd
        onUpdate(updatedClip)
    }
}

struct ColorGradingView: View {
    let grading: ColorGrading
    let onUpdate: (ColorGrading) -> Void

    @State private var brightness: Double
    @State private var contrast: Double
    @State private var saturation: Double
    @State private var warmth: Double
    @State private var selectedPreset: ColorGrading.ColorPreset

    init(grading: ColorGrading, onUpdate: @escaping (ColorGrading) -> Void) {
        self.grading = grading
        self.onUpdate = onUpdate
        _brightness = State(initialValue: grading.brightness)
        _contrast = State(initialValue: grading.contrast)
        _saturation = State(initialValue: grading.saturation)
        _warmth = State(initialValue: grading.warmth)
        _selectedPreset = State(initialValue: grading.preset)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Preset")
                .font(.caption)
            Picker("Preset", selection: $selectedPreset) {
                ForEach(ColorGrading.ColorPreset.allCases, id: \.self) { preset in
                    Text(preset.rawValue.capitalized).tag(preset)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedPreset) { _ in
                updateGrading()
            }

            VStack(alignment: .leading) {
                Text("Brightness: \(String(format: "%.2f", brightness))")
                    .font(.caption)
                Slider(value: $brightness, in: -1...1, step: 0.01)
                    .onChange(of: brightness) { _ in updateGrading() }
            }

            VStack(alignment: .leading) {
                Text("Contrast: \(String(format: "%.2f", contrast))")
                    .font(.caption)
                Slider(value: $contrast, in: 0...2, step: 0.01)
                    .onChange(of: contrast) { _ in updateGrading() }
            }

            VStack(alignment: .leading) {
                Text("Saturation: \(String(format: "%.2f", saturation))")
                    .font(.caption)
                Slider(value: $saturation, in: 0...2, step: 0.01)
                    .onChange(of: saturation) { _ in updateGrading() }
            }

            VStack(alignment: .leading) {
                Text("Warmth: \(String(format: "%.2f", warmth))")
                    .font(.caption)
                Slider(value: $warmth, in: -1...1, step: 0.01)
                    .onChange(of: warmth) { _ in updateGrading() }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal)
    }

    private func updateGrading() {
        let updatedGrading = ColorGrading(
            brightness: brightness,
            contrast: contrast,
            saturation: saturation,
            warmth: warmth,
            preset: selectedPreset
        )
        onUpdate(updatedGrading)
    }
}

struct PreviewPlayer: View {
    let clips: [VideoClip]

    var body: some View {
        ZStack {
            Color.black

            if let firstClip = clips.first {
                // In a real app, this would show actual video preview
                VStack {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white)
                    Text("\(clips.count) clips")
                        .foregroundColor(.white)
                        .font(.caption)
                }
            }
        }
    }
}
