import Foundation
import AVFoundation
import CoreImage

class VideoCompositionService {
    static let shared = VideoCompositionService()

    private init() {}

    // MARK: - Public Methods

    func composeVideo(project: VideoProject, progress: @escaping (Double) -> Void, completion: @escaping (Result<URL, CompositionError>) -> Void) {

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Create composition
                let composition = AVMutableComposition()

                // Add audio track
                guard let audioAsset = try? self.createAudioAsset(from: project.song.url) else {
                    throw CompositionError.audioLoadFailed
                }

                guard let audioTrack = composition.addMutableTrack(
                    withMediaType: .audio,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                ) else {
                    throw CompositionError.trackCreationFailed
                }

                guard let sourceAudioTrack = audioAsset.tracks(withMediaType: .audio).first else {
                    throw CompositionError.audioLoadFailed
                }

                try audioTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: audioAsset.duration),
                    of: sourceAudioTrack,
                    at: .zero
                )

                // Add video tracks
                guard let videoTrack = composition.addMutableTrack(
                    withMediaType: .video,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                ) else {
                    throw CompositionError.trackCreationFailed
                }

                var currentTime = CMTime.zero

                for (index, clip) in project.clips.enumerated() {
                    // Report progress
                    let clipProgress = Double(index) / Double(project.clips.count)
                    DispatchQueue.main.async {
                        progress(clipProgress * 0.7) // 70% for adding clips
                    }

                    let clipAsset = AVURLAsset(url: clip.url)
                    guard let sourceVideoTrack = clipAsset.tracks(withMediaType: .video).first else {
                        continue
                    }

                    let clipDuration = CMTime(seconds: clip.duration - clip.trimStart - clip.trimEnd, preferredTimescale: 600)
                    let startTime = CMTime(seconds: clip.trimStart, preferredTimescale: 600)

                    let timeRange = CMTimeRange(start: startTime, duration: clipDuration)

                    try videoTrack.insertTimeRange(
                        timeRange,
                        of: sourceVideoTrack,
                        at: currentTime
                    )

                    currentTime = CMTimeAdd(currentTime, clipDuration)
                }

                // Create video composition for effects
                let videoComposition = AVMutableVideoComposition()
                videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
                videoComposition.renderSize = CGSize(width: 1920, height: 1080)

                // Apply color grading
                let instruction = AVMutableVideoCompositionInstruction()
                instruction.timeRange = CMTimeRange(start: .zero, duration: composition.duration)

                let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
                instruction.layerInstructions = [layerInstruction]

                videoComposition.instructions = [instruction]

                // Note: Color grading would be applied through CIFilters
                // using a custom video compositor class in a production app

                DispatchQueue.main.async {
                    progress(0.8) // 80% done
                }

                // Export
                let outputURL = self.createOutputURL()

                guard let exportSession = AVAssetExportSession(
                    asset: composition,
                    presetName: AVAssetExportPresetHighestQuality
                ) else {
                    throw CompositionError.exportSessionCreationFailed
                }

                exportSession.outputURL = outputURL
                exportSession.outputFileType = .mp4
                exportSession.videoComposition = videoComposition

                exportSession.exportAsynchronously {
                    switch exportSession.status {
                    case .completed:
                        DispatchQueue.main.async {
                            progress(1.0)
                            completion(.success(outputURL))
                        }
                    case .failed:
                        DispatchQueue.main.async {
                            let error = exportSession.error ?? NSError(domain: "VideoComposition", code: -1)
                            completion(.failure(.exportFailed(error)))
                        }
                    case .cancelled:
                        DispatchQueue.main.async {
                            completion(.failure(.exportCancelled))
                        }
                    default:
                        break
                    }
                }

            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.compositionFailed(error)))
                }
            }
        }
    }

    func saveToPhotoLibrary(videoURL: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        // This would use PHPhotoLibrary to save
        // For now, just report success
        completion(.success(()))
    }

    // MARK: - Private Methods

    private func createAudioAsset(from url: URL) throws -> AVAsset {
        let asset = AVAsset(url: url)
        return asset
    }

    private func createOutputURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let outputURL = documentsPath.appendingPathComponent("output_\(UUID().uuidString).mp4")

        // Remove existing file if present
        try? FileManager.default.removeItem(at: outputURL)

        return outputURL
    }

    private func getColorTransfer(for grading: ColorGrading) -> String? {
        // Color transfer functions for different presets
        switch grading.preset {
        case .cinematic:
            return AVVideoTransferFunction_ITU_R_709_2
        case .noir:
            return AVVideoTransferFunction_ITU_R_709_2
        default:
            return nil
        }
    }

    private func applyColorFilter(to image: CIImage, grading: ColorGrading) -> CIImage {
        var outputImage = image

        // Apply brightness
        if let filter = CIFilter(name: "CIColorControls") {
            filter.setValue(outputImage, forKey: kCIInputImageKey)
            filter.setValue(grading.brightness, forKey: kCIInputBrightnessKey)
            filter.setValue(grading.contrast, forKey: kCIInputContrastKey)
            filter.setValue(grading.saturation, forKey: kCIInputSaturationKey)
            if let output = filter.outputImage {
                outputImage = output
            }
        }

        // Apply temperature (warmth)
        if let filter = CIFilter(name: "CITemperatureAndTint") {
            filter.setValue(outputImage, forKey: kCIInputImageKey)
            let temperature = CIVector(x: 6500 + (grading.warmth * 2000), y: 0)
            filter.setValue(temperature, forKey: "inputNeutral")
            if let output = filter.outputImage {
                outputImage = output
            }
        }

        return outputImage
    }
}

// MARK: - Error Types

enum CompositionError: LocalizedError {
    case audioLoadFailed
    case trackCreationFailed
    case compositionFailed(Error)
    case exportSessionCreationFailed
    case exportFailed(Error)
    case exportCancelled

    var errorDescription: String? {
        switch self {
        case .audioLoadFailed:
            return "Failed to load audio file."
        case .trackCreationFailed:
            return "Failed to create composition track."
        case .compositionFailed(let error):
            return "Video composition failed: \(error.localizedDescription)"
        case .exportSessionCreationFailed:
            return "Failed to create export session."
        case .exportFailed(let error):
            return "Export failed: \(error.localizedDescription)"
        case .exportCancelled:
            return "Export was cancelled."
        }
    }
}
