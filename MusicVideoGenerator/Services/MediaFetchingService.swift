import Foundation
import AVFoundation

class MediaFetchingService {
    static let shared = MediaFetchingService()

    private let pexelsAPIKey = "YOUR_PEXELS_API_KEY" // Users need to replace this
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public Methods

    func fetchVideos(for keywords: [String], mood: AudioAnalysis.Mood, duration: TimeInterval, completion: @escaping (Result<[VideoClip], MediaFetchError>) -> Void) {

        // Combine keywords with mood-based search terms
        let moodKeywords = getMoodKeywords(mood: mood)
        let searchQuery = (keywords + moodKeywords).joined(separator: " ")

        // Calculate how many clips we need (aim for coverage of the song)
        let clipDuration: TimeInterval = 5.0 // Average clip duration
        let numberOfClips = Int(ceil(duration / clipDuration))

        fetchPexelsVideos(query: searchQuery, count: numberOfClips) { result in
            switch result {
            case .success(let clips):
                completion(.success(clips))
            case .failure(let error):
                // Fallback to placeholder videos if fetch fails
                let placeholderClips = self.createPlaceholderClips(count: numberOfClips, duration: duration)
                completion(.success(placeholderClips))
            }
        }
    }

    // MARK: - Private Methods

    private func getMoodKeywords(mood: AudioAnalysis.Mood) -> [String] {
        switch mood {
        case .happy:
            return ["sunshine", "celebration", "joy", "bright"]
        case .sad:
            return ["rain", "melancholy", "alone", "cloudy"]
        case .energetic:
            return ["action", "dynamic", "movement", "sports"]
        case .calm:
            return ["peaceful", "nature", "serene", "quiet"]
        case .melancholic:
            return ["sunset", "nostalgia", "memories", "vintage"]
        case .uplifting:
            return ["inspiring", "sky", "sunrise", "hope"]
        case .aggressive:
            return ["intense", "power", "storm", "urban"]
        case .peaceful:
            return ["water", "zen", "meditation", "tranquil"]
        }
    }

    private func fetchPexelsVideos(query: String, count: Int, completion: @escaping (Result<[VideoClip], MediaFetchError>) -> Void) {

        guard !pexelsAPIKey.isEmpty && pexelsAPIKey != "YOUR_PEXELS_API_KEY" else {
            completion(.failure(.invalidAPIKey))
            return
        }

        // Pexels API endpoint
        let urlString = "https://api.pexels.com/videos/search?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&per_page=\(count)"

        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.addValue(pexelsAPIKey, forHTTPHeaderField: "Authorization")

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(.networkError(error)))
                }
                return
            }

            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.noData))
                }
                return
            }

            do {
                let result = try JSONDecoder().decode(PexelsResponse.self, from: data)
                let clips = self.convertPexelsToClips(pexelsVideos: result.videos)

                DispatchQueue.main.async {
                    completion(.success(clips))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(.decodingError(error)))
                }
            }
        }.resume()
    }

    private func convertPexelsToClips(pexelsVideos: [PexelsVideo]) -> [VideoClip] {
        return pexelsVideos.compactMap { video in
            guard let videoFile = video.videoFiles.first,
                  let videoURL = URL(string: videoFile.link),
                  let imageURL = URL(string: video.image) else {
                return nil
            }

            return VideoClip(
                url: videoURL,
                thumbnailURL: imageURL,
                duration: TimeInterval(video.duration),
                source: .stock,
                tags: video.tags,
                startTime: 0
            )
        }
    }

    private func createPlaceholderClips(count: Int, duration: TimeInterval) -> [VideoClip] {
        let clipDuration = duration / Double(count)
        var clips: [VideoClip] = []

        for i in 0..<count {
            // Create placeholder clips with generated colors
            if let placeholderURL = createPlaceholderVideo(index: i) {
                let clip = VideoClip(
                    url: placeholderURL,
                    duration: clipDuration,
                    source: .aiGenerated,
                    tags: ["placeholder"],
                    startTime: Double(i) * clipDuration
                )
                clips.append(clip)
            }
        }

        return clips
    }

    private func createPlaceholderVideo(index: Int) -> URL? {
        // In a real app, this would generate a simple colored video
        // For now, return a file URL placeholder
        let tempDir = FileManager.default.temporaryDirectory
        return tempDir.appendingPathComponent("placeholder_\(index).mp4")
    }
}

// MARK: - Pexels API Models

private struct PexelsResponse: Decodable {
    let videos: [PexelsVideo]
}

private struct PexelsVideo: Decodable {
    let id: Int
    let duration: Int
    let image: String
    let videoFiles: [VideoFile]
    let tags: [String]

    enum CodingKeys: String, CodingKey {
        case id, duration, image, tags
        case videoFiles = "video_files"
    }
}

private struct VideoFile: Decodable {
    let id: Int
    let quality: String
    let link: String
}

// MARK: - Error Types

enum MediaFetchError: LocalizedError {
    case invalidAPIKey
    case invalidURL
    case networkError(Error)
    case noData
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please configure your Pexels API key."
        case .invalidURL:
            return "Invalid URL for media fetch."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .noData:
            return "No data received from server."
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
