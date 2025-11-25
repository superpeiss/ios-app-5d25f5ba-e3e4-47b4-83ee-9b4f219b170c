import Foundation
import AVFoundation
import Accelerate

class AudioAnalyzerService {
    static let shared = AudioAnalyzerService()

    private init() {}

    // MARK: - Public Methods

    func analyze(audioURL: URL, completion: @escaping (Result<AudioAnalysis, AudioAnalysisError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let asset = AVAsset(url: audioURL)
                let duration = self.getAssetDuration(asset)

                // Load audio track
                guard let audioTrack = asset.tracks(withMediaType: .audio).first else {
                    DispatchQueue.main.async {
                        completion(.failure(.noAudioTrack))
                    }
                    return
                }

                // Extract audio samples
                let samples = try self.extractAudioSamples(from: asset, track: audioTrack)

                // Analyze tempo
                let tempo = self.analyzeTempo(samples: samples, duration: duration)

                // Analyze energy
                let energy = self.analyzeEnergy(samples: samples)

                // Determine mood
                let mood = self.determineMood(tempo: tempo, energy: energy)

                // Create segments
                let segments = self.createSegments(samples: samples, duration: duration)

                let analysis = AudioAnalysis(
                    tempo: tempo,
                    energy: energy,
                    mood: mood,
                    segments: segments
                )

                DispatchQueue.main.async {
                    completion(.success(analysis))
                }

            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.analysisFailure(error)))
                }
            }
        }
    }

    // MARK: - Private Methods

    private func getAssetDuration(_ asset: AVAsset) -> TimeInterval {
        return asset.duration.seconds
    }

    private func extractAudioSamples(from asset: AVAsset, track: AVAssetTrack) throws -> [Float] {
        let reader = try AVAssetReader(asset: asset)

        let outputSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]

        let readerOutput = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
        reader.add(readerOutput)
        reader.startReading()

        var samples: [Float] = []

        while let sampleBuffer = readerOutput.copyNextSampleBuffer() {
            if let blockBuffer = CMSampleBufferGetDataBuffer(sampleBuffer) {
                let length = CMBlockBufferGetDataLength(blockBuffer)
                var data = Data(count: length)

                data.withUnsafeMutableBytes { ptr in
                    CMBlockBufferCopyDataBytes(blockBuffer, atOffset: 0, dataLength: length, destination: ptr.baseAddress!)
                }

                let int16Samples = data.withUnsafeBytes { ptr in
                    Array(ptr.bindMemory(to: Int16.self))
                }

                // Convert Int16 to Float (-1.0 to 1.0)
                let floatSamples = int16Samples.map { Float($0) / Float(Int16.max) }
                samples.append(contentsOf: floatSamples)
            }
        }

        return samples
    }

    private func analyzeTempo(samples: [Float], duration: TimeInterval) -> Double {
        // Simple tempo detection using autocorrelation
        // This is a simplified implementation

        let sampleRate: Double = 44100.0
        let frameSize = 4096
        var beatStrength: [Double] = []

        for i in stride(from: 0, to: samples.count - frameSize, by: frameSize / 2) {
            let frame = Array(samples[i..<min(i + frameSize, samples.count)])
            let energy = frame.reduce(0.0) { $0 + Double($1 * $1) }
            beatStrength.append(energy)
        }

        // Find peaks in energy
        var peaks: [Int] = []
        for i in 1..<beatStrength.count - 1 {
            if beatStrength[i] > beatStrength[i - 1] && beatStrength[i] > beatStrength[i + 1] {
                peaks.append(i)
            }
        }

        if peaks.count < 2 {
            return 120.0 // Default tempo
        }

        // Calculate average interval between peaks
        var intervals: [Double] = []
        for i in 1..<peaks.count {
            let interval = Double(peaks[i] - peaks[i - 1])
            intervals.append(interval)
        }

        let avgInterval = intervals.reduce(0.0, +) / Double(intervals.count)
        let frameRate = sampleRate / Double(frameSize / 2)
        let bpm = (60.0 * frameRate) / avgInterval

        // Clamp to reasonable range
        return max(60.0, min(bpm, 180.0))
    }

    private func analyzeEnergy(samples: [Float]) -> Double {
        if samples.isEmpty {
            return 0.0
        }

        // Calculate RMS energy
        let sumOfSquares = samples.reduce(0.0) { $0 + Double($1 * $1) }
        let rms = sqrt(sumOfSquares / Double(samples.count))

        // Normalize to 0.0 - 1.0
        return min(rms * 10.0, 1.0)
    }

    private func determineMood(tempo: Double, energy: Double) -> AudioAnalysis.Mood {
        switch (tempo, energy) {
        case (0...80, 0...0.3):
            return .calm
        case (0...80, 0.3...0.6):
            return .melancholic
        case (0...80, 0.6...1.0):
            return .sad
        case (80...120, 0...0.4):
            return .peaceful
        case (80...120, 0.4...0.7):
            return .happy
        case (80...120, 0.7...1.0):
            return .uplifting
        case (120...200, 0...0.5):
            return .energetic
        case (120...200, 0.5...1.0):
            return .aggressive
        default:
            return .energetic
        }
    }

    private func createSegments(samples: [Float], duration: TimeInterval) -> [AudioSegment] {
        let segmentCount = 8
        let samplesPerSegment = samples.count / segmentCount
        let segmentDuration = duration / Double(segmentCount)

        var segments: [AudioSegment] = []

        for i in 0..<segmentCount {
            let start = i * samplesPerSegment
            let end = min(start + samplesPerSegment, samples.count)
            let segmentSamples = Array(samples[start..<end])

            let energy = analyzeEnergy(samples: segmentSamples)
            let dominantFrequency = analyzeDominantFrequency(samples: segmentSamples)

            let segment = AudioSegment(
                startTime: Double(i) * segmentDuration,
                duration: segmentDuration,
                energy: energy,
                dominantFrequency: dominantFrequency
            )

            segments.append(segment)
        }

        return segments
    }

    private func analyzeDominantFrequency(samples: [Float]) -> Double {
        // Simplified frequency analysis
        // In production, you'd use FFT here
        return 440.0 // Placeholder
    }
}

// MARK: - Error Types

enum AudioAnalysisError: LocalizedError {
    case noAudioTrack
    case analysisFailure(Error)
    case invalidAudioFormat

    var errorDescription: String? {
        switch self {
        case .noAudioTrack:
            return "No audio track found in the file."
        case .analysisFailure(let error):
            return "Audio analysis failed: \(error.localizedDescription)"
        case .invalidAudioFormat:
            return "Invalid audio format."
        }
    }
}
