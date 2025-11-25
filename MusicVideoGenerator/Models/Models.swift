import Foundation
import AVFoundation

// MARK: - Song Model
struct Song: Identifiable, Codable {
    let id: UUID
    var url: URL
    var title: String
    var duration: TimeInterval
    var analysis: AudioAnalysis?
    var lyrics: LyricsData?

    init(id: UUID = UUID(), url: URL, title: String, duration: TimeInterval) {
        self.id = id
        self.url = url
        self.title = title
        self.duration = duration
    }
}

// MARK: - Audio Analysis
struct AudioAnalysis: Codable {
    var tempo: Double // BPM
    var energy: Double // 0.0 - 1.0
    var mood: Mood
    var segments: [AudioSegment]

    enum Mood: String, Codable {
        case happy
        case sad
        case energetic
        case calm
        case melancholic
        case uplifting
        case aggressive
        case peaceful
    }
}

struct AudioSegment: Identifiable, Codable {
    let id: UUID
    var startTime: TimeInterval
    var duration: TimeInterval
    var energy: Double
    var dominantFrequency: Double

    init(id: UUID = UUID(), startTime: TimeInterval, duration: TimeInterval, energy: Double, dominantFrequency: Double) {
        self.id = id
        self.startTime = startTime
        self.duration = duration
        self.energy = energy
        self.dominantFrequency = dominantFrequency
    }
}

// MARK: - Lyrics Data
struct LyricsData: Codable {
    var fullText: String
    var timedSegments: [TimedLyric]
    var themes: [String]
    var keywords: [String]

    struct TimedLyric: Identifiable, Codable {
        let id: UUID
        var text: String
        var startTime: TimeInterval
        var duration: TimeInterval

        init(id: UUID = UUID(), text: String, startTime: TimeInterval, duration: TimeInterval) {
            self.id = id
            self.text = text
            self.startTime = startTime
            self.duration = duration
        }
    }
}

// MARK: - Video Clip
struct VideoClip: Identifiable, Codable {
    let id: UUID
    var url: URL
    var thumbnailURL: URL?
    var duration: TimeInterval
    var source: ClipSource
    var tags: [String]
    var startTime: TimeInterval // Position in final video
    var trimStart: TimeInterval // Trim from original clip
    var trimEnd: TimeInterval // Trim from original clip

    enum ClipSource: String, Codable {
        case stock
        case aiGenerated
        case userProvided
    }

    init(id: UUID = UUID(), url: URL, thumbnailURL: URL? = nil, duration: TimeInterval, source: ClipSource, tags: [String], startTime: TimeInterval = 0, trimStart: TimeInterval = 0, trimEnd: TimeInterval = 0) {
        self.id = id
        self.url = url
        self.thumbnailURL = thumbnailURL
        self.duration = duration
        self.source = source
        self.tags = tags
        self.startTime = startTime
        self.trimStart = trimStart
        self.trimEnd = trimEnd
    }
}

// MARK: - Transition
struct VideoTransition: Identifiable, Codable {
    let id: UUID
    var type: TransitionType
    var duration: TimeInterval

    enum TransitionType: String, Codable, CaseIterable {
        case dissolve
        case fade
        case wipe
        case push
        case none
    }

    init(id: UUID = UUID(), type: TransitionType, duration: TimeInterval = 0.5) {
        self.id = id
        self.type = type
        self.duration = duration
    }
}

// MARK: - Color Grading
struct ColorGrading: Codable {
    var brightness: Double // -1.0 to 1.0
    var contrast: Double // 0.0 to 2.0
    var saturation: Double // 0.0 to 2.0
    var warmth: Double // -1.0 to 1.0
    var preset: ColorPreset

    enum ColorPreset: String, Codable, CaseIterable {
        case none
        case cinematic
        case vibrant
        case vintage
        case noir
        case pastel
    }

    init(brightness: Double = 0, contrast: Double = 1, saturation: Double = 1, warmth: Double = 0, preset: ColorPreset = .none) {
        self.brightness = brightness
        self.contrast = contrast
        self.saturation = saturation
        self.warmth = warmth
        self.preset = preset
    }
}

// MARK: - Project
struct VideoProject: Identifiable, Codable {
    let id: UUID
    var name: String
    var song: Song
    var clips: [VideoClip]
    var transitions: [VideoTransition]
    var colorGrading: ColorGrading
    var createdAt: Date
    var modifiedAt: Date
    var exportURL: URL?

    init(id: UUID = UUID(), name: String, song: Song) {
        self.id = id
        self.name = name
        self.song = song
        self.clips = []
        self.transitions = []
        self.colorGrading = ColorGrading()
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}
