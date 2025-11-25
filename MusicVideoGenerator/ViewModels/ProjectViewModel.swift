import Foundation
import Combine
import AVFoundation

class ProjectViewModel: ObservableObject {
    @Published var project: VideoProject?
    @Published var isAnalyzing = false
    @Published var isGenerating = false
    @Published var isExporting = false
    @Published var progress: Double = 0.0
    @Published var errorMessage: String?
    @Published var currentStep: ProcessStep = .upload

    enum ProcessStep {
        case upload
        case analyzing
        case generating
        case editing
        case exporting
        case completed
    }

    private let audioAnalyzer = AudioAnalyzerService.shared
    private let lyricsTranscriber = LyricsTranscriptionService.shared
    private let mediaFetcher = MediaFetchingService.shared
    private let videoComposer = VideoCompositionService.shared

    // MARK: - Public Methods

    func createProject(from audioURL: URL, title: String) {
        let asset = AVAsset(url: audioURL)
        let duration = asset.duration.seconds

        let song = Song(url: audioURL, title: title, duration: duration)
        self.project = VideoProject(name: title, song: song)
        self.currentStep = .analyzing
        self.analyzeAudio()
    }

    func analyzeAudio() {
        guard let project = project else { return }

        isAnalyzing = true
        errorMessage = nil
        progress = 0.0

        // Analyze audio
        audioAnalyzer.analyze(audioURL: project.song.url) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let analysis):
                self.project?.song.analysis = analysis
                self.progress = 0.5
                self.transcribeLyrics()

            case .failure(let error):
                self.isAnalyzing = false
                self.errorMessage = error.localizedDescription
                // Continue without lyrics if analysis fails
                self.generateVideo()
            }
        }
    }

    private func transcribeLyrics() {
        guard let project = project else { return }

        lyricsTranscriber.transcribe(audioURL: project.song.url) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let lyrics):
                self.project?.song.lyrics = lyrics
                self.progress = 1.0
                self.isAnalyzing = false
                self.generateVideo()

            case .failure:
                // Continue without lyrics
                self.isAnalyzing = false
                self.generateVideo()
            }
        }
    }

    func generateVideo() {
        guard let project = project else { return }
        guard let analysis = project.song.analysis else {
            errorMessage = "Audio analysis is required before generating video."
            return
        }

        isGenerating = true
        currentStep = .generating
        progress = 0.0

        let keywords = project.song.lyrics?.keywords ?? []

        mediaFetcher.fetchVideos(
            for: keywords,
            mood: analysis.mood,
            duration: project.song.duration
        ) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let clips):
                self.project?.clips = clips
                self.arrangeClips()
                self.isGenerating = false
                self.currentStep = .editing
                self.progress = 1.0

            case .failure(let error):
                self.isGenerating = false
                self.errorMessage = error.localizedDescription
            }
        }
    }

    private func arrangeClips() {
        guard var project = project else { return }

        var currentTime: TimeInterval = 0

        for i in 0..<project.clips.count {
            project.clips[i].startTime = currentTime

            // Adjust clip duration to fit better
            let remainingDuration = project.song.duration - currentTime
            if project.clips[i].duration > remainingDuration {
                project.clips[i].trimEnd = project.clips[i].duration - remainingDuration
            }

            currentTime += (project.clips[i].duration - project.clips[i].trimStart - project.clips[i].trimEnd)

            if currentTime >= project.song.duration {
                // Remove remaining clips if we've covered the song
                project.clips = Array(project.clips[0...i])
                break
            }
        }

        self.project = project
    }

    func updateClip(_ clip: VideoClip) {
        guard var project = project,
              let index = project.clips.firstIndex(where: { $0.id == clip.id }) else {
            return
        }

        project.clips[index] = clip
        self.project = project
    }

    func removeClip(_ clip: VideoClip) {
        guard var project = project else { return }
        project.clips.removeAll { $0.id == clip.id }
        self.project = project
        arrangeClips()
    }

    func updateColorGrading(_ grading: ColorGrading) {
        project?.colorGrading = grading
    }

    func exportVideo(completion: @escaping (Result<URL, Error>) -> Void) {
        guard let project = project else {
            completion(.failure(NSError(domain: "ProjectViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No project available"])))
            return
        }

        isExporting = true
        currentStep = .exporting
        progress = 0.0

        videoComposer.composeVideo(project: project, progress: { [weak self] prog in
            self?.progress = prog
        }, completion: { [weak self] result in
            guard let self = self else { return }

            self.isExporting = false

            switch result {
            case .success(let url):
                self.project?.exportURL = url
                self.currentStep = .completed
                self.progress = 1.0
                completion(.success(url))

            case .failure(let error):
                self.errorMessage = error.localizedDescription
                completion(.failure(error))
            }
        })
    }

    func reset() {
        project = nil
        isAnalyzing = false
        isGenerating = false
        isExporting = false
        progress = 0.0
        errorMessage = nil
        currentStep = .upload
    }
}
